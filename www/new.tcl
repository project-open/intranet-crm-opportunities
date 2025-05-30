# /packages/intranet-crm-opportunities/www/new.tcl

# Copyright (c) 2003-now ]project-open[

# All rights reserved. Please check
# https://www.project-open.com/license/ for details.

ad_page_contract {

    @param opportunity_id if specified, we edit the opportunity with this opportunity_id
    @param return_url Return URL

    @author klaus.hofeditz@project-open.com
    @author frank.bergmann@project-open.com

} {
    opportunity_id:integer,optional 
    { project_name "" }
    { project_nr "" }
    { project_path "" }
    { project_type_id "" }
    { project_status_id "" }
    { company_id:integer,optional } 
    { company_contact_id:integer,optional } 
    { opportunity_sales_stage_id 0}
    { opportunity_priority_id 0}
    { form_mode "edit" }
    { return_url "" }
}

# ------------------------------------------------------
# Defaults & Security
# ------------------------------------------------------

set user_id [auth::require_login]
set user_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
set required_field "<font color=red size=+1><B>*</B></font>"

set action_url "/intranet-crm-opportunities/new-2"
set focus "menu.var_name"
set current_url [im_url_with_query]
set page_title  [lang::message::lookup "" intranet-crm-opportunities.CreateOpportunity "Create Opportunity"]
if {[info exists project_type_id] && "" ne $project_type_id && 0 ne $project_type_id} {
    append page_title ": [im_category_from_id $project_type_id]"
}


# Required for updating user 
set auto_login [im_generate_auto_login -user_id [ad_conn user_id]]
set default_currency [im_parameter -package_id [im_package_cost_id] "DefaultCurrency" "" "EUR"]

if { ![info exists company_id] } { set company_id 0 }

set opportunity_subtypes_exist_p [expr [llength [im_sub_categories [im_project_type_opportunity]]] > 1]

set validation_error_p 0

# ------------------------------------------------------------------
# Permissions & Form mode
# ------------------------------------------------------------------

# Check if we are creating a new opportunity or editing an existing one:
set opportunity_exists_p 0
if {[info exists opportunity_id]} {
    set opportunity_exists_p [db_string opportunity_exists "
	select 	count(*) 
	from 	im_projects 
	where 	project_id = :opportunity_id
    "]
} 

if {$opportunity_exists_p} {
    # Check opportunity permissions for this user
    im_project_permissions $user_id $opportunity_id view read write admin
    if {!$write} {
        ad_return_complaint 1 "<li>[_ intranet-core.lt_Insufficient_Privileg]:<br> [_ intranet-core.lt_You_are_not_authorize]</li>"
        return
    }

    # Get the project_type_id for DynField handling1
    db_1row opportunity_info "
	select	project_type_id
	from	im_projects
	where	project_id = :opportunity_id	         
    "

} else {
    # Does the current user has the right to create a new opportunity?
    if {![im_permission $user_id add_projects]} {
        ad_return_complaint 1 "<li>[_ intranet-core.lt_Insufficient_Privileg]: add_projects<br> [_ intranet-core.lt_You_are_not_authorize]</li>"
        return
    }
}


# ------------------------------------------------------------------
# Redirect if project_type_id or project_sla_id are missing
# ------------------------------------------------------------------

if {"edit" == $form_mode} {
    set redirect_p 0
    # redirect if project_type_id is not defined
    if {("" == $project_type_id || 0 == $project_type_id) && (![info exists opportunity_id] || $opportunity_id eq "")} {
	set all_same_p [im_dynfield::subtype_have_same_attributes_p -parent_category_id [im_project_type_opportunity] -object_type "im_project"]
	if {!$all_same_p} { set redirect_p 1 }
    }

    # Redirect in order to define the SLA and the project type
    if {$redirect_p} {
	set new_typeselect_url_default "/intranet-crm-opportunities/new-typeselect"
	set new_typeselect_url [parameter::get_from_package_key -package_key "intranet-crm-opportunities" -parameter "NewTypeSelectUrl" -default $new_typeselect_url_default]
	if {"" == $new_typeselect_url} { set new_typeselect_url $new_typeselect_url_default }
	ad_returnredirect [export_vars -base $new_typeselect_url {{return_url $current_url} opportunity_id project_type_id project_name project_nr project_sla_id}]
    }
}

if {"" eq $project_type_id} { set project_type_id [im_project_type_opportunity] }


# ------------------------------------------------------------------
# Build the form
# ------------------------------------------------------------------

set form_id "opportunity"
set opportunity_status_options [list]
set opportunity_type_options [list]
set label_new_company [lang::message::lookup "" intranet-crm-opportunities.CreateNewCompany "New Company"]
set label_new_cust_contact [lang::message::lookup "" intranet-crm-opportunities.CreateNewCostumerContact "New Customer Contact"]

ad_form \
    -name $form_id \
    -cancel_url $return_url \
    -mode $form_mode \
    -export {next_url user_id return_url also_add_users} \
    -form {
    	opportunity_id:key
    }

# Opportunity name
template::element::create $form_id project_name \
    -label [lang::message::lookup "" intranet-core.OpportunityName "Opportunity Name"] \
    -datatype text \
    -html {size 50} 

# Opportunity Nr
template::element::create $form_id project_nr -optional \
    -label [lang::message::lookup "" intranet-core.OpportunityNumber "Opportunity Nr"] \
    -datatype text \
    -html {size 15} \
    -value [im_next_project_nr]



if {$opportunity_subtypes_exist_p} {
    template::element::create $form_id project_type_id \
	-label "[lang::message::lookup {} intranet-crm-opportunities.Opportunity_Type {Opportunity Type}]" \
	-widget "hidden" \
	-value $project_type_id \
    ]
}

# company_id
template::element::create $form_id company_id \
    -label "[_ intranet-crm-opportunities.OpportunityCustomer]" \
    -widget "select" \
    -html { style "width:300px" } \
    -options [im_company_options -include_empty_p 1 -status "Active or Potential" -type "CustOrIntl"]

if { "edit" == $form_mode } {
    set after_html_val "&nbsp;<span id=\"company_name\"></span><input id=\"btn_loadNewCompany\" type=\"button\" name=\"\" value=\"$label_new_company\">"
    template::element::set_properties $form_id company_id after_html $after_html_val
}

# company_contact_id
template::element::create $form_id company_contact_id -optional \
    -label "[_ intranet-crm-opportunities.OpportunityCustomerContact]" \
    -widget "select" \
    -options "" \
    -optional

if { "edit" == $form_mode } {
    set after_html_val "&nbsp;<input type=\"button\" id=\"btn_loadNewCompanyContact\" name=\"Create new company\" value=\"$label_new_cust_contact\">"
    template::element::set_properties $form_id company_contact_id after_html $after_html_val
}

# ------------------------------------------------------
# Dynamic Fields
# ------------------------------------------------------

set my_opportunity_id 0
if {[info exists opportunity_id]} { set my_opportunity_id $opportunity_id }

# Add dynfields to the form
im_dynfield::append_attributes_to_form \
    -include_also_hard_coded_p 1 \
    -object_type "im_project" \
    -form_id $form_id \
    -object_subtype_id $project_type_id \
    -object_id $my_opportunity_id \
    -form_display_mode $form_mode

	
# ------------------------------------------------------
# Form 
# ------------------------------------------------------
 
ad_form -extend -name $form_id -select_query {
 	select
 		*
 	from 
 		im_projects 
 	where 
 		project_id = :opportunity_id

} -new_data {

    if {[info exists presales_probability] && ($presales_probability < 0 || $presales_probability > 100)} {
	ad_return_complaint 1 "[lang::message::lookup "" intranet-crm-opportunities.OpportunityPresalesProbabilityOutOfRange "Presales probability must be between 0 and 100"]"
	ad_script_abort
    }

    # Make opportunity_sales_stage_id mandatory because we need is at an identifier to determine what project had been resulted out of a lead 
    # Should be covered by DynField Attribute - just doublecheck in case this Dynfield is been removed 
    if { ![info exists opportunity_sales_stage_id] || "" == $opportunity_sales_stage_id } {
	ad_return_complaint 1 "[lang::message::lookup "" intranet-crm-opportunities.OpportunitySalesStageMissing "Please provide a value for 'Sales Stage'"]"
	ad_script_abort
    }

    # Basic Sanity checks to avoid that user creates double entries 
    set project_name_exist_p [db_string get_data " select count(*) from im_projects where project_name = :project_name" -default 0]
    set project_nr_exist_p [db_string get_data " select count(*) from im_projects where project_nr = :project_nr OR project_path = :project_nr" -default 0]

    if { $project_name_exist_p } {ad_return_complaint 1 [lang::message::lookup "" intranet-crm-opportunities.ProjectNameExists "Project Name already exists, please choose a different Project Name"]}
    if { $project_nr_exist_p} {ad_return_complaint 1 [lang::message::lookup "" intranet-crm-opportunities.ProjectNrExists "Project Nr already exists, please choose a different Project Nr"]}

    if {[catch {
        set opportunity_id [im_project::new \
                      -project_name       $project_name \
                      -project_nr         $project_nr \
                      -project_path       $project_nr \
                      -company_id         $company_id \
                      -project_type_id    $project_type_id \
                      -project_status_id  [im_project_status_potential] \
		      ]
    } err_msg]} {
	global errorInfo
	ns_log Error $errorInfo
	ad_return_complaint 1  "[lang::message::lookup "" intranet-crm-opportunities.OpportunityCreationFailed "Unable to create opportunity"] $errorInfo"
        ad_script_abort
    }

    if {0 == $opportunity_id || "" == $opportunity_id} {
            ad_return_complaint 1 "<b>Error creating project</b>:<br>
                We have got an error creating a new project.<br>
                There is probably something wrong with the projects's parameters below:<br>&nbsp;<br>
                <pre>
                project_name            $project_name
                project_nr              $project_nr
                project_path            $project_path
                company_id              $company_id
                project_type_id         $project_type_id
                </pre><br>&nbsp;<br>
                For reference, here is the error message:<br>
                <pre>$err_msg</pre>
            "
            ad_script_abort
    }

    # New BizRel   
    if {[info exists project_lead_id] && "" ne $project_lead_id} {
    	im_biz_object_add_role $project_lead_id $opportunity_id [im_biz_object_role_project_manager]
    }

    set list_updates [list]
    if {[info exists company_contact_id] } {lappend list_updates "company_contact_id = :company_contact_id"}

    if {[catch {
    	db_dml project_update "update im_projects set [join $list_updates ","] where project_id = :opportunity_id"
    } err_msg]} {
	global errorInfo
	ns_log Error $errorInfo
	ad_return_complaint 1 "[lang::message::lookup "" intranet-crm-opportunities.OpportunityCreationFailed "Unable to create opportunity"] $errorInfo"
	ad_script_abort
    }
	
    # Store Dynfields 
    im_dynfield::attribute_store \
        -object_type im_project \
        -object_id $opportunity_id \
        -form_id $form_id

    # User Exit & Audit/Call Back
    im_user_exit_call project_create $opportunity_id
    im_audit -object_type im_project -action after_create -object_id $opportunity_id -status_id $opportunity_sales_stage_id -type_id $project_type_id -debug_p 1

    set return_url [export_vars -base "/intranet-crm-opportunities/view" {opportunity_id}]
    ns_log Notice "intranet-crm-opportunities/new: After 'new'"
    
} -on_request {

    if {$opportunity_exists_p} {
	set company_id_select [db_string get_data "select company_id from im_projects where project_id = :opportunity_id" -default 0]
	template::element::set_properties $form_id company_contact_id options [im_customer_contact_options -include_empty_p 1 $company_id_select ]
    }

} -edit_data {
    
    # -----------------------------------------------------------------
    # Update the Opportunity
    # -----------------------------------------------------------------

    if {[info exists presales_probability] && ($presales_probability < 0 || $presales_probability > 100)} {
	ad_return_complaint 1 "[lang::message::lookup "" intranet-crm-opportunities.OpportunityPresalesProbabilityOutOfRange "Presales probability must be between 0 and 100"]"
	ad_script_abort
    }

    # Make opportunity_sales_stage_id mandatory because we need is at an identifier to determine what project had been resulted out of a lead
    # Should be covered by DynField Attribute - just doublecheck in case this Dynfield is been removed
    if { ![info exists opportunity_sales_stage_id] || "" == $opportunity_sales_stage_id } {
	ad_return_complaint 1 "[lang::message::lookup "" intranet-crm-opportunities.OpportunitySalesStageMissing "Please provide a value for 'Sales Stage'"]"
	ad_script_abort
    }

    if { [info exists company_contact_id] && "" == $company_contact_id } {
	set company_contact_id_sql ", company_contact_id = null"
    } else {
	set company_contact_id_sql ", company_contact_id = :company_contact_id"
    }

    if { [info exists company_contact_id] && "" == $company_contact_id } {
        set company_contact_id_sql ", company_contact_id = null"
    } else {
        set company_contact_id_sql ", company_contact_id = :company_contact_id"
    }

    # Adjust project_status_id 
    if { [lsearch [im_sub_categories 84018] $opportunity_sales_stage_id] != -1 } {
        set opportunity_sales_stage_id_sql ", project_status_id = [im_project_status_closed]"
    } else {
	set opportunity_sales_stage_id_sql ", project_status_id = [im_project_status_potential]"
    }

    set opportunity_update_sql "
        update im_projects set
                project_name =  	:project_name,
                project_nr =    	:project_nr,
                project_type_id = 	:project_type_id,
                company_id =    	:company_id
		$company_contact_id_sql
		$opportunity_sales_stage_id_sql
        where
                project_id = :opportunity_id
    "

    db_dml opportunity_update $opportunity_update_sql

    # Store Dynfields
    im_dynfield::attribute_store \
        -object_type "im_project" \
        -object_id $opportunity_id \
        -form_id $form_id \
	-object_id $opportunity_id

    # AUDIT 
    im_audit -object_type "im_project" -object_id $opportunity_id -action after_update
    
    # -----------------------------------------------------------------
    # Store dynamic fields
    # -----------------------------------------------------------------
    
     set form_id "opportunity"
     set object_type "im_project"
     
     ns_log Notice "intranet-crm-opportunities/new: before append_attributes_to_form"
     im_dynfield::append_attributes_to_form \
     	-object_type im_project \
     	-form_id opportunity \
     	-object_id $opportunity_id 
     
     ns_log Notice "intranet-crm-opportunities/new: before attribute_store"
     im_dynfield::attribute_store \
     	-object_type im_project \
     	-object_id $opportunity_id \
     	-form_id $form_id
     
    # ------------------------------------------------------
    # Finish
    # ------------------------------------------------------
    
    # Flush the opportunity cache
    # im_project::flush_cache
    
    # Not sure if still necessary...
    db_release_unused_handles
    
    # Return to the new opportunity page after creating
    if {"" == $return_url} {
    	set return_url [export_vars -base "/intranet-crm-opportunities/new?" {opportunity_id {form_mode display}} ]
    }

} -after_submit {

    ns_log Notice "intranet-crm-opportunities/new: after_submit: ad_returnredirect $return_url"
    ad_returnredirect $return_url

} -on_validation_error {
	set validation_error_p 1
}

