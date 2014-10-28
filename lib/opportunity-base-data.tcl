ad_page_contract {
    Display 'Opportunity Base Data' 
    @author iuri.sampaio@gmail.com
    @author klaus.hofeditz@project-open.com
    @date 2014-10-07
} 

# ---------------------------------------------------------------------
# Get Everything about the Opportunity
# ---------------------------------------------------------------------


set extra_selects [list "0 as zero"]
db_foreach column_list_sql {}  {
    lappend extra_selects "${deref_plpgsql_function}($attribute_name) as ${attribute_name}_deref"
}
    
set extra_select [join $extra_selects ",\n\t"]

    
if { ![db_0or1row project_info_query {}] } {
    ad_return_complaint 1 "[_ intranet-core.lt_Cant_find_the_project]"
    return
}

set user_id [ad_conn user_id] 

# ---------------------------------------------------------------------
# Redirect to timesheet if this is timesheet
# ---------------------------------------------------------------------

# Redirect if this is a timesheet task (subtype of project)
if {$project_type_id == [im_project_type_task]} {
    ad_returnredirect [export_vars -base "/intranet-timesheet2-tasks/new" {{task_id $project_id}}]
}

# ---------------------------------------------------------------------
# Check permissions
# ---------------------------------------------------------------------

# get the current users permissions for this project                                                                                                         
im_project_permissions $user_id $opportunity_id view read write admin

set current_user_id $user_id


# ---------------------------------------------------------------------
# Opportunity Base Data
# ---------------------------------------------------------------------  

set im_company_link_tr [im_company_link_tr $user_id $company_id $company_name "[_ intranet-core.Client]"]
set im_render_user_id [im_render_user_id $project_lead_id $project_lead $user_id $opportunity_id]
set im_render_company_contact_id [im_render_user_id $company_contact_id $company_contact $user_id $opportunity_id]
set creation_date [db_string get_data "select to_char(creation_date, 'YYYY-MM-DD') from acs_objects where object_id = :opportunity_id " -default ""]

# ---------------------------------------------------------------------
# Add DynField Columns to the display

db_multirow -extend {attrib_var value} project_dynfield_attribs dynfield_attribs_sql {} {
    set var ${attribute_name}_deref
    set value [expr $$var]

    # Empty values will be skipped anyway
    if {"" != [string trim $value]} {
	set attrib_var [lang::message::lookup "" intranet-core.$attribute_name $pretty_name]

	set translate_p 0
	switch $acs_datatype {
	    boolean - string { set translate_p 1 }
	}
	switch $widget {
	    im_category_tree - checkbox - generic_sql - select { set translate_p 1 }
	    richtext - textarea - text - date { set translate_p 0 }
	}
	
	set value_l10n $value
	if {$translate_p} {
	    # ToDo: Is lang::util::suggest_key the right way? Or should we just use blank substitution?
	    set value_l10n [lang::message::lookup "" intranet-core.[lang::util::suggest_key $value] $value] 
	}
	set value $value_l10n
    }
}

set edit_project_base_data_p [im_permission $current_user_id edit_project_basedata]

if { ![info exists return_url] || "" == $return_url } {
    set return_url "/intranet-crm-opportunities/view?opportunity_id=$opportunity_id"
}
