# /intranet-crm-opportunities/tcl/intranet-crm-opportunities-procs.tcl
#

ad_library {
    @author klaus.hofeditz@project-open.com
    @author frank.bergmann@project-open.com
}

# -----------------------------------------------------------
# Constant Functions
# -----------------------------------------------------------

ad_proc -public im_opportunity_sales_stage_prospecting {} { return 84010} 
ad_proc -public im_opportunity_sales_stage_qualification {} { return 84011} 
ad_proc -public im_opportunity_sales_stage_needs_analysis {} { return 84012}
ad_proc -public im_opportunity_sales_stage_value_proposition {} { return 84013}
ad_proc -public im_opportunity_sales_stage_id_decision_makers {} { return 84014}
ad_proc -public im_opportunity_sales_stage_perception_analysis {} { return 84015}
ad_proc -public im_opportunity_sales_stage_proposal_price_quote {} { return 84016}
ad_proc -public im_opportunity_sales_stage_negotiation_review {} { return 84017} 
ad_proc -public im_opportunity_sales_stage_closed {} { return 84018} 
ad_proc -public im_opportunity_sales_stage_closed_won {} { return 84019}
ad_proc -public im_opportunity_sales_stage_closed_lost {} { return 84020}

# -----------------------------------------------------------
# Business Logic
# -----------------------------------------------------------

ad_proc -public im_next_opportunity_nr { 
    {-customer_id 0 }
    {-parent_id "" }
    {-nr_digits}
    {-date_format}
} {
    Returns the next free lead number

    Returns "" if there was an error calculating the number.
    Lead_nr's look like: 2003_0123 with the first 4 digits being
    the current year and the last 4 digits as the current number
    within the year.
    <p>
    The SQL query works by building the maximum of all numeric (the 8 
    substr comparisons of the last 4 digits) lead numbers
    of the current year (comparing the first 4 digits to the current year),
    adding "+1", and contatenating again with the current year.
} {
    # Set default values from parameters
    if {![info exists nr_digits]} {
        set nr_digits [parameter::get -package_id [im_package_core_id] -parameter "ProjectNrDigits" -default "4"]
    }
    if {![info exists date_format]} {
        set date_format [parameter::get -package_id [im_package_core_id] -parameter "ProjectNrDateFormat" -default "YYYY_"]
    }

    # Check for a custom project_nr generator
    set project_nr_generator [parameter::get -package_id [im_package_core_id] -parameter "CustomProjectNrGenerator" -default ""]

    if {"" != $project_nr_generator} {
        return [eval $project_nr_generator -customer_id $customer_id -nr_digits $nr_digits -date_format $date_format]
    }

    # Should we create hierarchial project numbers for sub-projects?
    set project_nr_hierarchical_digits [parameter::get -package_id [im_package_core_id] -parameter "ProjectNrHierarchicalDigits" -default 0]

    # ----------------------------------------------------
    # Calculate the next invoice Nr by finding out the last
    # one +1

    set todate [db_string today "select to_char(now(), :date_format)"]
    if {"none" == $date_format} { set date_format "" }

    # Adjust the position of the start of date and nr in the invoice_nr
    set date_format_len [string length $date_format]
    set nr_start_idx [expr 1+$date_format_len]
    set date_start_idx 1

    set num_check_sql ""
    set zeros ""
    for {set i 0} {$i < $nr_digits} {incr i} {
        set digit_idx [expr 1 + $i]
        append num_check_sql "
                and ascii(substr(p.nr,$digit_idx,1)) > 47
                and ascii(substr(p.nr,$digit_idx,1)) < 58
        "
        append zeros "0"
    }

    # ----------------------------------------------------
    # Check if we create a sub-project or even sub-sub-project etc.
    # Then we just replace the variables above.
    if {"" != $parent_id && $project_nr_hierarchical_digits > 0} {
        set parent_project_nr ""
        db_0or1row parent_project_info "
                select  project_nr as parent_project_nr
                from    im_projects
                where   project_id = :parent_id
        "

        set nr_digits $project_nr_hierarchical_digits
        set date_format "${parent_project_nr}_"
        set todate $date_format
        set date_format_len [string length $date_format]
        set nr_start_idx [expr 1+$date_format_len]
        set date_start_idx 1
        set zeros ""
        set num_check_sql ""
        for {set i 0} {$i < $nr_digits} {incr i} {
            set digit_idx [expr 1 + $i]
            append num_check_sql "
                and ascii(substr(p.nr,$digit_idx,1)) > 47
                and ascii(substr(p.nr,$digit_idx,1)) < 58
            "
            append zeros "0"
        }
    }

    # ----------------------------------------------------
    # Pull out the largest number that fits the PPPPPPPP_xxxx format

    set sql "
        select
                trim(max(p.nr)) as last_project_nr
        from (
                 select substr(project_nr, :nr_start_idx, :nr_digits) as nr
                 from   im_projects
                 where  substr(project_nr, :date_start_idx, :date_format_len) = '$todate'
             ) p
        where   1=1
                $num_check_sql
    "

    set last_project_nr [db_string max_project_nr $sql -default $zeros]
    set last_project_nr [string trimleft $last_project_nr "0"]
    if {[empty_string_p $last_project_nr]} { set last_project_nr 0 }
    set next_number [expr $last_project_nr + 1]

    # ----------------------------------------------------
    # Put together the new project_nr
    set nr_sql "select '$todate' || trim(to_char($next_number,:zeros)) as project_nr"
    set project_nr [db_string next_project_nr $nr_sql -default ""]
    return $project_nr

}


ad_proc -public im_opportunity_base_data_component {
    {-opportunity_id}
    {-return_url}
} {
    returns basic project info with dynfields and hard coded
    Original version from ]po[
} {
    set params [list [list base_url "/intranet-core/"]  [list opportunity_id $opportunity_id] ]
    if { [info exists return_url] } { lappend params [list return_url $return_url] }
    set result [ad_parse_template -params $params "/packages/intranet-crm-opportunities/lib/opportunity-base-data"]
    return [string trim $result]
}


ad_proc -public im_opportunity_pipeline {
    {-diagram_width 300 }
    {-diagram_height 300 }
    {-diagram_caption "" }
} {
    Returns a HTML code with a Sencha diagram showing
    the current opportunities, together with
    presales_probability and presales_value.
} {
    # Sencha check and permissions
    if {![im_sencha_extjs_installed_p]} { return "" }
    im_sencha_extjs_load_libraries

    set params [list \
		    [list diagram_width $diagram_width] \
		    [list diagram_height $diagram_height] \
		    [list diagram_caption $diagram_caption]
    ]

    set result [ad_parse_template -params $params "/packages/intranet-crm-opportunities/lib/opportunity-pipeline"]
    return [string trim $result]
}


# ----------------------------------------------------------------------
# Navigation Bar
# ---------------------------------------------------------------------

ad_proc -public im_crm_navbar { 
    {-navbar_menu_label "crm"}
    default_letter 
    base_url 
    next_page_url 
    prev_page_url 
    export_var_list 
    {select_label ""} 
} {
    Returns rendered HTML code for a horizontal sub-navigation
    bar for /intranet-crm-opportunities/.
    The lower part of the navbar also includes an Alpha bar.

    @param default_letter none marks a special behavious, hiding the alpha-bar.
    @navbar_menu_label Determines the "parent menu" for the menu tabs for 
    search shortcuts, defaults to "projects".
} {
    # -------- Calculate Alpha Bar with Pass-Through params -------
    set bind_vars [ns_set create]
    foreach var $export_var_list {
	upvar 1 $var value
	if { [info exists value] } {
	    ns_set put $bind_vars $var $value
	}
    }
    set alpha_bar [im_alpha_bar -prev_page_url $prev_page_url -next_page_url $next_page_url $base_url $default_letter $bind_vars]

    # Get the Subnavbar
    set parent_menu_sql "select menu_id from im_menus where label = '$navbar_menu_label'"
    set parent_menu_id [util_memoize [list db_string parent_admin_menu $parent_menu_sql -default 0]]
    
    ns_set put $bind_vars letter $default_letter
    ns_set delkey $bind_vars project_status_id

    set navbar [im_sub_navbar $parent_menu_id $bind_vars $alpha_bar "tabnotsel" $select_label]

    return $navbar
}

