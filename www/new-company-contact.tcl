# /packages/intranet-crm-opportunities/www/new-company-contact.tcl
#
# Copyright (C) 2003-now ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract {
    @param company_id company_id 
    @author klaus.hofeditz@project-open.com
} {
    company_id:integer
    { user_id:integer "" }
    { return_url "" }
    { home_phone "" }
    { work_phone "" }
    { cell_phone "" }
    { fax "" }
    { aim_screen_name "" }
    { icq_number "" }
    { wa_line1 "" }
    { wa_line2 "" }
    { wa_city "" }
    { wa_state "" }
    { wa_postal_code "" }
    { wa_country_code "" }
    { note "" }
}

# ------------------------------------------------------
# Defaults & Security
# ------------------------------------------------------

set current_user_id [auth::require_login]

# Check if current_user_id can create new users
if {![im_permission $current_user_id add_users]} {
    ad_return_complaint 1 "<li>[_ intranet-core.lt_You_have_insufficient_4]"
    return
}

# Pre-generate user_id for double-click protection
set user_id [db_nextval acs_object_id_seq]

set form_id "new-company-contact" 


ad_form \
	-name new-company-contact \
	-export {next_url user_id return_url} \
	-form {
	    {email:text(text) {label "[_ intranet-core.Email]"} {html {size 30}}}
	    {first_names:text(text) {label "[_ intranet-core.First_names]"} {html {size 30}}}
	    {last_name:text(text) {label "[_ intranet-core.Last_name]"} {html {size 30}}}
	}

#-- --------------------------------------
#   Appending Dynfields
#-- --------------------------------------

# Append sub-type-dynfields (Salutation)
if {([info exists profile] && $profile ne "")} {
    set profile_org $profile
} else {
    set profile_org [list]
}
set user_subtypes [im_user_subtypes $user_id]
if { ""==$user_subtypes} { set user_subtypes $profile_org }

im_dynfield::append_attributes_to_form \
    -object_subtype_id $user_subtypes \
    -object_type "person" \
    -form_id $form_id \
    -object_id $user_id \
    -page_url "/intranet-crm-opportunities/new-company-contact.tcl" 

# Append "regular" Dynfields
set country_options [im_country_options]
set dynfield_list [db_list get_dynfields_person "select attribute_name from acs_attributes where object_type='person'"]

ad_form -extend -name $form_id -form {
    # hidden field company contact 
    {company_id:text(hidden) {value $company_id}}
}

if {"home_phone" ni $dynfield_list} { ad_form -extend -name $form_id -form { {home_phone:text(text),optional {label "[_ intranet-core.Home_phone]"} {html {size 30}}} }}
if {"work_phone" ni $dynfield_list} { ad_form -extend -name $form_id -form { {work_phone:text(text),optional {label "[_ intranet-core.Work_phone]"} {html {size 30}}} }}
if {"cell_phone" ni $dynfield_list} { ad_form -extend -name $form_id -form { {cell_phone:text(text),optional {label "[_ intranet-core.Cell_phone]"} {html {size 30}}} }}
if {"fax" ni $dynfield_list} { ad_form -extend -name $form_id -form { {fax:text(text),optional {label "[_ intranet-core.Fax]"} {html {size 30}}} }}
if {"aim_screen_name" ni $dynfield_list} { ad_form -extend -name $form_id -form { {aim_screen_name:text(text),optional {label "[_ intranet-core.Aim_Screen_Name]"} {html {size 30}}} }}
if {"icq_number" ni $dynfield_list} { ad_form -extend -name $form_id -form { {icq_number:text(text),optional {label "[_ intranet-core.ICQ_Number]"} {html {size 30}}} }}
if {"wa_line1" ni $dynfield_list} { ad_form -extend -name $form_id -form { {wa_line1:text(text),optional {label "[_ intranet-core.Work_address]"} {html {size 30}}} }}
if {"wa_line2" ni $dynfield_list} { ad_form -extend -name $form_id -form { {wa_line2:text(text),optional {label "[_ intranet-core.Work_address]"} {html {size 30}}} }}
if {"wa_city" ni $dynfield_list} { ad_form -extend -name $form_id -form { {wa_city:text(text),optional {label "[_ intranet-core.Work_City]"} {html {size 30}}} }}
if {"wa_state" ni $dynfield_list} { ad_form -extend -name $form_id -form { {wa_state:text(text),optional {label "[_ intranet-core.Work_State]"} {html {size 30}}} }}
if {"wa_postal_code" ni $dynfield_list} { ad_form -extend -name $form_id -form { {wa_postal_code:text(text),optional {label "[_ intranet-core.Work_Postal_Code]"} {html {size 30}}} }}
if {"wa_country_code" ni $dynfield_list} { ad_form -extend -name $form_id -form { {wa_country_code:text(select),optional {label "[_ intranet-core.Country]"} {options $country_options} } }}
if {"note" ni $dynfield_list} { ad_form -extend -name $form_id -form { {note:text(text),optional {label "[_ intranet-core.Users_Contact_Note]"} {html {size 50}}} }}

ad_form -extend -name $form_id -on_request {

} -on_submit {

    if {![im_permission $current_user_id add_users]} {
	ad_return_complaint 1 "<li>[_ intranet-core.lt_You_have_no_rights_to]"
	return
    }
    
    set email [string trim $email]
    set username $email
    set screen_name ""
    set password [ad_generate_random_string]
    set url ""
    set secret_question ""
    set secret_answer ""

    # Sanity check for email
    set existing_user_id [db_string get_number_emails "select party_id from parties where email = :email" -default 0]
    if { 0 != $existing_user_id } {
        set msg [lang::message::lookup "" intranet-crm-opportunities.UserExists "The user you are trying to create already exists in the system. For additional information please see his/her <a target=\"_blank\" href=\"/intranet/users/view?user_id=$existing_user_id\">user account</a>. "]
	append msg "<br>[lang::message::lookup "" intranet-crm-opportunities.CloseWindowAssignmentManually "Please close this window by clicking 'Cancel' in the top right corner and make make the necessary assignments manually"]"
        ns_return 200 text/html $msg
    }

    if {[catch {
	# Create user 
	array set creation_info [auth::create_user \
                                 -user_id $user_id \
                                 -verify_password_confirm \
                                 -username $username \
                                 -email $email \
                                 -first_names $first_names \
                                 -last_name $last_name \
                                 -screen_name $screen_name \
                                 -password $password \
                                 -password_confirm $password \
                                 -url $url \
                                 -secret_question $secret_question \
				 -secret_answer $secret_answer]

	# Add the user to the "Registered Users" group
	set registered_users [db_string registered_users "select object_id from acs_magic_objects where name='registered_users'"]
	set reg_users_rel_exists_p [db_string member_of_reg_users "
                select  count(*)
                from    group_member_map m, membership_rels mr
                where   m.member_id = :user_id
                        and m.group_id = :registered_users
                        and m.rel_id = mr.rel_id
                        and m.container_id = m.group_id
                        and m.rel_type::text = 'membership_rel'::text
        "]

	if {!$reg_users_rel_exists_p} {
            relation_add -member_state "approved" "membership_rel" $registered_users $user_id
	}

	# Make user member of group "Customer"
	im_profile::add_member -profile_id [im_profile_customers] -user_id $user_id

	# Make user member of Company
	im_biz_object_add_role $user_id $company_id 1300

	# Store contact information 
	set sql "
		 insert into users_contact (
			user_id, 
			home_phone, 
			work_phone, 
			cell_phone, 
			fax, 
			aim_screen_name, 
			icq_number, 
			wa_line1, 
			wa_line2, 
			wa_city, 
			wa_state, 
			wa_postal_code, 
			wa_country_code, 
			note 
		 ) values ( 
			:user_id, 
			:home_phone, 
			:work_phone, 
			:cell_phone, 
			:fax, 	
			:aim_screen_name, 
			:icq_number, 
			:wa_line1, 
			:wa_line2,
       			:wa_city,
			:wa_state, 
			:wa_postal_code, 
			:wa_country_code, 
			:note
		)
	"

	if {[catch {
	    db_dml write_comtact_info $sql
	} err_msg]} {
	    global errorInfo
	    ns_log Error $errorInfo
	    ad_return_complaint 1  "[lang::message::lookup "" intranet-crm-opportunities.Db_Error "Unable to write contact information"]: $errorInfo"
	}

	# Store Dynfields
	im_dynfield::attribute_store \
	    -object_type "person" \
	    -object_id $user_id \
	    -form_id $form_id

	# TSearch2: We need to update "persons" in order to trigger the TSearch2 triggers
	db_dml update_persons "update persons set first_names = first_names where person_id = :user_id"

	# Call the "user_create" user_exit
	im_user_exit_call user_create $user_id
	
	# Audit
	im_audit -object_type person -action after_create -object_id $user_id

	db_release_unused_handles

	ns_returnredirect "contact-created?new_contact_id=$user_id"

    } err_msg]} {
	set user_id 0
	ad_return_complaint xx $err_msg
	ns_log Error $err_msg
    }
}
