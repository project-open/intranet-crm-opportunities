# /packages/intranet-crm-opportunities/www/opportunities.tcl
#
# Copyright (C) 2016 various parties
# The software is based on ArsDigita ACS 3.4

# ---------------------------------------------------------------
# 1. Page Contract
# ---------------------------------------------------------------

ad_page_contract { 
    List all opportunitys

    @param order_by opportunity display order 
    @param mine_p:
	"t": Show only mine
    @param start_idx the starting index for query
    @param how_many how many rows to return

    @author klaus.hofeditz@project-open.com
    @author frank.bergmann@project-open.com
    
} {
    { order_by "Prio" }
    { mine_p "f" }
    { project_type_id:integer 0 } 
    { company_id:integer 0 } 
    { opportunity_sales_stage_id 84021 }
    { start_idx:integer 0 }
    { start_date "" }
    { end_date "" }
    { how_many "" }
    { view_name "opportunity_list" }
    { filter_advanced_p:integer 0 }
    { owner_id:integer 0 }
    { user_id_from_search 0}
}

# ---------------------------------------------------------------
# 1. Defaults & Security
# ---------------------------------------------------------------

# User id already verified by filters

set show_context_help_p 0

set user_id [auth::require_login]
set admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
set subsite_id [ad_conn subsite_id]
set current_user_id $user_id
set today [lindex [split [ns_localsqltimestamp] " "] 0]
set page_title  [lang::message::lookup "" intranet-crm-opportunities.Opportunities "Opportunities"]
set context_bar [im_context_bar $page_title]
set return_url [im_url_with_query]
set default_currency [parameter::get -package_id [apm_package_id_from_key intranet-cost] -parameter "DefaultCurrency" -default "USD"]

# Create an action select at the bottom if the "view" has been designed for it...
# set show_bulk_actions_p [string equal "project_timeline" $view_name]
set show_bulk_actions_p 0

if { $how_many eq "" || $how_many < 1 } {
    set how_many [parameter::get -package_id [apm_package_id_from_key intranet-core] -parameter "NumberResultsPerPage" -default 50]
}
set end_idx [expr {$start_idx + $how_many}]

# Set the "menu_select_label" for the project navbar:
# projects_open, projects_closed and projects_potential
# depending on type_id and status_id:
#
# set menu_select_label ""
#switch $project_status_id {
#    71 { set menu_select_label "projects_potential" }
#    76 { set menu_select_label "projects_open" }
#    81 { set menu_select_label "projects_closed" }
#    default { set menu_select_label "" }
# }


set min_all_l10n [lang::message::lookup "" intranet-core.Mine_All "Mine/All"]
set all_l10n [lang::message::lookup "" intranet-core.All "All"]

if { "" != $start_date } {
    if {[catch {
        if { $start_date != [clock format [clock scan $start_date] -format %Y-%m-%d] } {
            ad_return_complaint 1 "<strong>[_ intranet-core.Start_Date]</strong> [lang::message::lookup "" intranet-core.IsNotaValidDate "is not a valid date"].<br>
            [lang::message::lookup "" intranet-core.Current_Value "Current value"]: '$start_date'<br>"
        }
    } err_msg]} {
        ad_return_complaint 1 "<strong>[_ intranet-core.Start_Date]</strong> [lang::message::lookup "" intranet-core.DoesNotHaveRightFormat "doesn't have the right format"].<br>
        [lang::message::lookup "" intranet-core.Current_Value "Current value"]: '$start_date'<br>
        [lang::message::lookup "" intranet-core.Expected_Format "Expected Format"]: 'YYYY-MM-DD'"
    }
}

if { "" != $end_date } {
    if {[catch {
        if { $end_date != [clock format [clock scan $end_date] -format %Y-%m-%d] } {
            ad_return_complaint 1 "<strong>[_ intranet-core.End_Date]</strong> [lang::message::lookup "" intranet-core.IsNotaValidDate "is not a valid date"].<br>
            [lang::message::lookup "" intranet-core.Current_Value "Current value"]: '$end_date'<br>"
        }
    } err_msg]} {
        ad_return_complaint 1 "<strong>[_ intranet-core.End_Date]</strong> [lang::message::lookup "" intranet-core.DoesNotHaveRightFormat "doesn't have the right format"].<br>
        [lang::message::lookup "" intranet-core.Current_Value "Current value"]: '$end_date'<br>
        [lang::message::lookup "" intranet-core.Expected_Format "Expected Format"]: 'YYYY-MM-DD'"
    }
}

# ---------------------------------------------------------------
# 3. Defined Table Fields
# ---------------------------------------------------------------

# Define column headers and column contents 

set view_id [db_string get_view_id "select view_id from im_views where view_name=:view_name" -default 0]
if {!$view_id } {
     ad_return_complaint 1 "<b>Unknown View Name</b>:<br>
     The view '$view_name' is not defined. <br>
     Maybe you need to upgrade the database. <br>
     Please notify your system administrator."
}

set column_headers [list]
set column_vars [list]
set column_headers_admin [list]
set extra_selects [list]
set extra_froms [list]
set extra_wheres [list]
set view_order_by_clause ""

set column_sql "
	select	vc.*
	from	im_view_columns vc
	where	view_id=:view_id and
		group_id is null
	order by sort_order
"

db_foreach column_list_sql $column_sql {
    set admin_html ""
    if {$admin_p} { 
	set url [export_vars -base "/intranet/admin/views/new-column" {column_id return_url}]
	set admin_html "<a href='$url'>[im_gif wrench ""]</a>" 
    }

    if {"" == $visible_for || [eval $visible_for]} {
	lappend column_headers "$column_name"
	lappend column_vars "$column_render_tcl"
	lappend column_headers_admin $admin_html
	if {"" != $extra_select} { lappend extra_selects $extra_select }
	if {"" != $extra_from} { lappend extra_froms $extra_from }
	if {"" != $extra_where} { lappend extra_wheres $extra_where }
	if {"" != $order_by_clause &&
	    $order_by==$column_name} {
	    set view_order_by_clause $order_by_clause
	}
    }
}

# ---------------------------------------------------------------
# Filter with Dynamic Fields
# ---------------------------------------------------------------

set form_id "opportunity_filter"
set object_type "im_project"
set action_url "/intranet-crm-opportunities/opportunities"
set form_mode "edit"

ad_form \
    -name $form_id \
    -action $action_url \
    -mode $form_mode \
    -method GET \
    -export {start_idx order_by how_many view_name filter_advanced_p}\
    -form {}

if {[im_permission $current_user_id "view_projects_all"]} { 
    # Mine/All
    set mine_p_options [list \
			    [list $all_l10n "f" ] \
			    [list [lang::message::lookup "" intranet-core.Mine "Mine"] "t"] \
			   ]
    ad_form -extend -name $form_id -form {{mine_p:text(select),optional {label "$min_all_l10n"} {options $mine_p_options }}}

    #-- --------------------------------
    #   With Member
    #-- --------------------------------
    # Get the list of profiles readable for current_user_id
    set managable_profiles [im_profile::profile_options_managable_for_user -privilege "read" $current_user_id]
    # Extract only the profile_ids from the managable profiles
    set user_select_groups {}
    foreach g $managable_profiles { lappend user_select_groups [lindex $g 1] }
    set user_options [im_profile::user_options -profile_ids $user_select_groups]
    set user_options [linsert $user_options 0 [list $all_l10n ""]]
    ad_form -extend -name $form_id -form {{user_id_from_search:text(select),optional {label #intranet-core.With_Member#} {options $user_options}}}

} else {
    set mine_p "f"
}

set company_options [im_company_options -include_empty_p 1 -include_empty_name $all_l10n -status "CustOrIntl"]

if {!$filter_advanced_p} {
    ad_form -extend -name $form_id -form {
	{company_id:text(select),optional {label \#intranet-core.Customer\#} {options $company_options}}
    }

    ad_form -extend -name $form_id -form {
        {opportunity_sales_stage_id:text(im_category_tree),optional {label \#intranet-crm-opportunities.OpportunitySalesStage\#} {value $opportunity_sales_stage_id} {custom {category_type "Intranet Opportunity Sales Stage" translate_p 1 include_empty_name $all_l10n}} }
    }
}

#ad_form -extend -name $form_id -form {
#    {start_date:text(text) {label "[_ intranet-timesheet2.Start_Date]"} {value "$start_date"} {html {size 10}} {after_html {<input type="button" style="height:20px; width:20px; background: url('/resources/acs-templating/calendar.gif');" onclick ="return showCalendar('start_date', 'y-m-d');" >}}}
#    {end_date:text(text) {label "[_ intranet-timesheet2.End_Date]"} {value "$end_date"} {html {size 10}} {after_html {<input type="button" style="height:20px; width:20px; background: url('/resources/acs-templating/calendar.gif');" onclick ="return showCalendar('end_date', 'y-m-d');" >}}}
# }

set filter_admin_html ""
if {$filter_advanced_p} {
    im_dynfield::append_attributes_to_form \
        -object_type $object_type \
	-object_subtype_id [im_project_type_opportunity] \
        -form_id $form_id \
        -object_id 0 \
        -advanced_filter_p 1 \
	-include_also_hard_coded_p 1 \
	-page_url $action_url

    # Set the form values from the HTTP form variable frame
    im_dynfield::set_form_values_from_http -form_id $form_id
    im_dynfield::set_local_form_vars_from_http -form_id $form_id

    array set extra_sql_array [im_dynfield::search_sql_criteria_from_form \
				   -form_id $form_id \
				   -object_type $object_type
			      ]
    # Show an admin wrench for setting up the filter design
    if {$admin_p} {
	set filter_admin_url [export_vars -base "/intranet-dynfield/layout-position" {{object_type im_project} {page_url $action_url}}]
	set filter_admin_html "<a href='$filter_admin_url'>[im_gif wrench]</a>"
    }
}

# ---------------------------------------------------------------
# 5. Generate SQL Query
# ---------------------------------------------------------------

set criteria [list]
if { $opportunity_sales_stage_id ne "" && $opportunity_sales_stage_id != 0 } {
    lappend criteria "p.opportunity_sales_stage_id in ([join [im_sub_categories $opportunity_sales_stage_id] ","])"
}
if { $company_id ne "" && $company_id != 0 } {
    lappend criteria "p.company_id=:company_id"
}
if {"" != $start_date} {
    lappend criteria "p.end_date >= :start_date::timestamptz"
}

set order_by_clause "order by lower(project_nr) DESC"

switch [string tolower $order_by] {
    "prio" { set order_by_clause "order by opportunity_priority_id ASC" }
    "nr" { set order_by_clause "order by project_nr desc" }
    "name" { set order_by_clause "order by lower(project_name)" }
    "company" { set order_by_clause "order by lower(company_name)" }
    "contact" { set order_by_clause "order by lower(contact_name)" }
    "sales stage" { set order_by_clause "order by opportunity_sales_stage_id" }
    "presales value" { set order_by_clause "order by presales_value DESC" }
    "probability" { set order_by_clause "order by presales_probability DESC" }
    "weighted value" { set order_by_clause "order by opportunity_weighted_value DESC" }
    "owner" { set order_by_clause "order by opportunity_owner" }
    "campaign" { set order_by_clause "order by campaign_name" }
    "created" { set order_by_clause "order by creation_date DESC" }
    default {
	if {$view_order_by_clause ne ""} {
	    set order_by_clause "order by $view_order_by_clause"
	}
    }
}

set where_clause [join $criteria " and\n            "]
if { $where_clause ne "" } {
    set where_clause " and $where_clause"
}

set extra_select [join $extra_selects ",\n\t"]
if { $extra_select ne "" } {
    set extra_select ",\n\t$extra_select"
}

set extra_from [join $extra_froms ",\n\t"]
if { $extra_from ne "" } {
    set extra_from ",\n\t$extra_from"
}

set extra_where [join $extra_wheres "and\n\t"]
if { $extra_where ne "" } {
    set extra_where ",\n\t$extra_where"
}

# Create a ns_set with all local variables in order
# to pass it to the SQL query
set form_vars [ns_set create]
foreach varname [info locals] {
    # Don't consider variables that start with a "_", that
    # contain a ":" or that are array variables:
    if {"_" == [string range $varname 0 0]} { continue }
    if {[regexp {:} $varname]} { continue }
    if {[array exists $varname]} { continue }

    # Get the value of the variable and add to the form_vars set
    set value [expr "\$$varname"]
    ns_set put $form_vars $varname $value
}


# Deal with DynField Vars and add constraint to SQL
if {$filter_advanced_p} {
    set dynfield_extra_where $extra_sql_array(where)
    set ns_set_vars $extra_sql_array(bind_vars)
    set tmp_vars [util_list_to_ns_set $ns_set_vars]
    set tmp_var_size [ns_set size $tmp_vars]
    for {set i 0} {$i < $tmp_var_size} { incr i } {
	set key [ns_set key $tmp_vars $i]
	set value [ns_set get $tmp_vars $key]
	ns_set put $form_vars $key $value
    }
    # Add the additional condition to the "where_clause"
    if {"" != $dynfield_extra_where} {
	append where_clause "
	    and project_id in $dynfield_extra_where
        "
    }
}


set create_date ""
set open_date ""
set quote_date ""
set deliver_date ""
set invoice_date ""
set close_date ""

# Show all opportunities where user is a member of
set perm_sql "
	(
	-- member projects
	select	p.*
	from	im_projects p,
		acs_rels r
	where	r.object_id_one = p.project_id
		and r.object_id_two in (select :user_id from dual UNION select group_id from group_element_index where element_id = :user_id)
		$where_clause
	)
"

# -- ---------------------------------------------------------- 
#    Permissions 
# -- ---------------------------------------------------------- 

# User can see all opportunities - no permissions
if {[im_permission $user_id "view_projects_all"]} {
   set perm_sql "im_projects"
}

# Explicitely looking for the user's opportunities
if {"t" == $mine_p} {
    set perm_sql "
	(select	p.*
	from	im_projects p
	where	p.project_lead_id = :user_id
		$where_clause
	)"
}

#Mine 
if { "t" == $mine_p } {
    set mine_where "and (p.project_lead_id = :current_user_id)"
} else {
    set mine_where "and 1=1"
}

# With member
if {0 != $user_id_from_search && "" != $user_id_from_search} {
    set user_id_where "and (p.project_id in (select object_id_one from acs_rels where object_id_two = :user_id_from_search) OR p.project_lead_id = :user_id_from_search)"
} else {
    set user_id_where "and 1=1"
}

# Project Type Where Clause
if { [lsearch -exact [im_sub_categories [im_opportunity_sales_stage_closed]] $opportunity_sales_stage_id] != -1 } {
    # Look up all Project Types, indicator if Project resulted from an CRM Opportunity is a value in attribute 'opportunity_sales_stage_id'
    set project_type_where_clause " and p.opportunity_sales_stage_id IS NOT NULL" 
} else {
    set project_type_where_clause " and p.project_type_id = [im_project_type_opportunity]" 
}


# -- ---------------------------------------------------------- 
#    Main SQL 
# -- ---------------------------------------------------------- 

set sql "
SELECT 
	*
FROM
        ( SELECT
                p.*,
		trim(to_char(coalesce(p.presales_value,0.0), '99,999,999,999,999,999.99')) as presales_value_pretty,
		coalesce(presales_value,0.0) * coalesce(presales_probability,0) / 100.0 as opportunity_weighted_value,
		round((p.presales_value * im_exchange_rate(now()::date,p.presales_value_currency, :default_currency)) :: numeric,2) as presales_value_converted,
		p.project_id as opportunity_id,
		im_name_from_user_id(p.company_contact_id) as contact_name, 
		im_name_from_user_id(p.project_lead_id) as opportunity_owner,
		(select project_name from im_projects where project_id = opportunity_campaign_id) as campaign_name,
                c.company_name,
                to_char(p.start_date, 'YYYY-MM-DD') as start_date_formatted,
		to_char(o.creation_date, 'YYYY-MM-DD') as creation_date
		$extra_select
        FROM
                $perm_sql p,
                im_companies c,
		acs_objects o
		$extra_from
        WHERE
                p.company_id = c.company_id
		and o.object_id = p.project_id
		$project_type_where_clause
                $where_clause
		$extra_where
		$mine_where
		$user_id_where
        ) projects





$order_by_clause
"


# ---------------------------------------------------------------
# 5a. Limit the SQL query to MAX rows and provide << and >>
# ---------------------------------------------------------------

# Limit the search results to N data sets only to be able to manage large sites

# We can't get around counting in advance if we want to be able to
# sort inside the table on the page for only those users in the
# query results
set total_in_limited [db_string total_in_limited "
        select count(*)
        from ($sql) s
"]

# Special case: FIRST the users selected the 2nd page of the results
# and THEN added a filter. Let's reset the results for this case:
while {$start_idx > 0 && $total_in_limited < $start_idx} {
    set start_idx [expr {$start_idx - $how_many}]
    set end_idx [expr {$end_idx - $how_many}]
}
set selection [im_select_row_range $sql $start_idx $end_idx]



# ---------------------------------------------------------------
# 6. Format the Filter
# ---------------------------------------------------------------


set mine_p_options [list \
	[list $all_l10n "f" ] \
	[list [lang::message::lookup "" intranet-core.Mine "Mine"] "t"] \
]

# ----------------------------------------------------------
# Build administration links

set admin_html "<ul>"

set links [im_menu_crm_admin_links]
foreach link_entry $links {
    set html ""
    for {set i 0} {$i < [llength $link_entry]} {incr i 2} {
        set name [lindex $link_entry $i]
        set url [lindex $link_entry $i+1]
        append html "<a href='$url'>$name</a>"
    }
    append admin_html "<li>$html</li>\n"
}

# Append user-defined menus
set bind_vars [list return_url $return_url]
append admin_html [im_menu_ul_list -no_uls 1 "crm_admin" $bind_vars]
append admin_html "</ul>"


# ---------------------------------------------------------------
# 7. Format the List Table Header
# ---------------------------------------------------------------

# Set up colspan to be the number of headers + 1 for the # column
set colspan [expr {[llength $column_headers] + 1}]
set table_header_html ""

# Format the header names with links that modify the
# sort order of the SQL query.
#
set url "$action_url?"
set query_string [export_ns_set_vars url [list order_by]]
if { $query_string ne "" } {
    append url "$query_string&"
}

append table_header_html "<tr>\n"
set ctr 0
foreach col $column_headers {

    set wrench_html [lindex $column_headers_admin $ctr]
    regsub -all " " $col "_" col_txt
    set col_txt [lang::message::lookup "" intranet-core.$col_txt $col]
    if {$ctr == 0 && $show_bulk_actions_p} {
	append table_header_html "<td class=rowtitle>$col_txt$wrench_html</td>\n"
    } else {
	#set col [lang::util::suggest_key $col]
	append table_header_html "<td class=rowtitle><a href=\"${url}order_by=[ns_urlencode $col]\">$col_txt</a>$wrench_html</td>\n"
    }
    incr ctr
}
append table_header_html "</tr>\n"


# ---------------------------------------------------------------
# 8. Format the Result Data
# ---------------------------------------------------------------

set table_body_html ""
set bgcolor(0) " class=roweven "
set bgcolor(1) " class=rowodd "
set ctr 0
set idx $start_idx
set presales_value_sum_converted 0
set weighted_value_sum_converted 0

db_foreach projects_info_query $selection -bind $form_vars {

    if { [lsearch -exact [im_sub_categories [im_opportunity_sales_stage_open]] $opportunity_sales_stage_id] >= 0 } {
	set project_link "<a href=/intranet-crm-opportunities/create-project-from-opportunity?opportunity_id=$opportunity_id>[lang::message::lookup "" intranet-crm-opportunities.CreateProject "Create"]</a>"
    } elseif { $opportunity_sales_stage_id == [im_opportunity_sales_stage_closed_won] } {
	set project_link "<a href=/intranet-crm-opportunities/create-project-from-opportunity?opportunity_id=$opportunity_id>[lang::message::lookup "" intranet-crm-opportunities.SeeProject "See Project"]</a>"
    } else {
	set project_link "-"
    }

    set project_type [im_category_from_id $project_type_id]

    # Multi-Select
    set select_project_checkbox "<input type=checkbox name=select_project_id value=$project_id id=select_project_id,$project_id>"

    set url [im_maybe_prepend_http $url]
    if { $url eq "" } {
	set url_string "&nbsp;"
    } else {
	set url_string "<a href=\"$url\">$url</a>"
    }
    
    # Build sum Presales Value
    if { [info exists presales_value_converted] && "" != $presales_value_converted} {
	set presales_value_sum_converted [expr $presales_value_converted + $presales_value_sum_converted]
    }

    # set Weighted Value and build sum 
    set opportunity_weighted_value [lc_numeric "0" "%.2f" "en_US"]
    if { [info exists presales_value_converted] && "" != $presales_value_converted && [info exists presales_probability] && "" != $presales_probability} {
	set opportunity_weighted_value [lc_numeric [expr {$presales_value * $presales_probability / 100}] "%.2f" "en_US"]
	set weighted_value_converted [expr {$presales_value_converted * $presales_probability / 100}]
	set weighted_value_sum_converted [expr {$weighted_value_converted + $weighted_value_sum_converted}]
    } 

    # Append together a line of data based on the "column_vars" parameter list
    set row_html "<tr$bgcolor([expr {$ctr % 2}])>\n"
    foreach column_var $column_vars {
	append row_html "\t<td valign=top>"
	set cmd "append row_html $column_var"
	if {[catch {
	    eval "$cmd"
	} errmsg]} {
            global errorInfo
	    ns_log Error "Error creating table based on Dynview:\n$errorInfo "
	    im_feedback_add_message "config" $errorInfo "" "Minor error - some data might be missing due to misconfigured 'DynView'. Check error.log for more information." 
	}
	append row_html "</td>\n"
    }
    append row_html "</tr>\n"
    append table_body_html $row_html

    incr ctr
    if { $how_many > 0 && $ctr > $how_many } {
	break
    }
    incr idx

}

set statistics "
<table cellpadding=\"0\" cellspacing=\"0\" border=\"0\" width=\"100%\">
<tr>
<td>&nbsp;&nbsp;&nbsp;</td>
<td align='left'>[lang::message::lookup "" intranet-crm-opportunities.PresalesValueSum "Sum Presales Value"]: </td>
<td align='right'>[lc_numeric $presales_value_sum_converted "%.2f" "en_US"] $default_currency</td>
</tr>
<tr>
<td></td>
<td align='left'>[lang::message::lookup "" intranet-crm-opportunities.WeightedValueSum "Sum Weighted Value"]: </td>
<td align='right'>[lc_numeric $weighted_value_sum_converted "%.2f" "en_US"] $default_currency</td>
</tr>
</table>" 

# Show a reasonable message when there are no result rows:
if { $table_body_html eq "" } {
    set table_body_html "
        <tr><td colspan=$colspan><ul><li><b> 
	[lang::message::lookup "" intranet-core.lt_There_are_currently_n "There are currently no entries matching the selected criteria"]
        </b></ul></td></tr>"
}

if { $end_idx < $total_in_limited } {
    # This means that there are rows that we decided not to return
    # Include a link to go to the next page
    set next_start_idx [expr {$end_idx + 0}]
    set next_page_url "index?start_idx=$next_start_idx&amp;[export_ns_set_vars url [list start_idx]]"
} else {
    set next_page_url ""
}

if { $start_idx > 0 } {
    # This means we didn't start with the first row - there is
    # at least 1 previous row. add a previous page link
    set previous_start_idx [expr {$start_idx - $how_many}]
    if { $previous_start_idx < 0 } { set previous_start_idx 0 }
    set previous_page_url "index?start_idx=$previous_start_idx&amp;[export_ns_set_vars url [list start_idx]]"
} else {
    set previous_page_url ""
}

# ---------------------------------------------------------------
# 9. Format Table Continuation
# ---------------------------------------------------------------

# Check if there are rows that we decided not to return
# => include a link to go to the next page
#
if {$total_in_limited > 0 && $end_idx < $total_in_limited} {
    set next_start_idx [expr {$end_idx + 0}]
    set next_page "<a href=index?start_idx=$next_start_idx&amp;[export_ns_set_vars url [list start_idx]]>Next Page</a>"
} else {
    set next_page ""
}

# Check if this is the continuation of a table (we didn't start with the
# first row - there is at least 1 previous row.
# => add a previous page link
#
if { $start_idx > 0 } {
    set previous_start_idx [expr {$start_idx - $how_many}]
    if { $previous_start_idx < 0 } { set previous_start_idx 0 }
    set previous_page "<a href=index?start_idx=$previous_start_idx&amp;[export_ns_set_vars url [list start_idx]]>Previous Page</a>"
} else {
    set previous_page ""
}

set table_continuation_html "
<tr>
  <td align=center colspan=$colspan>
    [im_maybe_insert_link $previous_page $next_page]
  </td>
</tr>"

if {$show_bulk_actions_p} {
    set table_continuation_html "
	<tr>
	<td colspan=99>[im_project_action_select]</td>
	</tr>
$table_continuation_html
    "
}


# ---------------------------------------------------------------
# Sub-Navbar
# ---------------------------------------------------------------

set crm_navbar_html [im_crm_navbar "none" $action_url "" "" [list] "crm_opportunities"]



# Compile and execute the formtemplate if advanced filtering is enabled.
eval [template::adp_compile -string {<formtemplate id="opportunity_filter" style="tiny-plain-po"></formtemplate>}]
set filter_html $__adp_output

# Left Navbar is the filter/select part of the left bar
set left_navbar_html "
	<div class='filter-block'>
        	<div class='filter-title'>
	            [lang::message::lookup "" intranet-crm-opportunities.FilterOpportunities "Filter Opportunities"] $filter_admin_html
        	</div>
            	$filter_html
      	</div>
      <hr/>
      	<div class='filter-block'>
        <div class='filter-title'>
	     [lang::message::lookup "" intranet-crm-opportunities.Opportunities "Opportunities"]
        </div>
	$admin_html
      	</div>
      <hr/>
        <div class='filter-block'>
        <div class='filter-title'>
             [lang::message::lookup "" intranet-crm-opportunities.LeadQueue "Lead Queue"]
        </div>
        $statistics
        </div>
"
