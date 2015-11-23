#
# Copyright (C) 2014- various parties
# The software is based on ArsDigita ACS 3.4
#
# This program is free software. You can redistribute it
# and/or modify it under the terms of the GNU General
# Public License as published by the Free Software Foundation;
# either version 2 of the License, or (at your option)
# any later version. This program is distributed in the
# hope that it will be useful, but WITHOUT ANY WARRANTY;
# without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.

ad_page_contract {
    View all the info about a specific project.
    @param opportunity_id the group id
    
    @author frank.bergmann@project-open.com
    @author klaus.hofeditz@project-open.com

} {
    { opportunity_id:integer 0}
    { view_name "standard"}
}

# ---------------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------------
# Redirect if this is a task or a project 

if {([info exists opportunity_id] && $opportunity_id ne "")} {
    set otype [db_string otype "select object_type from acs_objects where object_id = :opportunity_id" -default ""]
    if {"im_timesheet_task" == $otype} {
	ad_returnredirect [export_vars -base "/intranet-timesheet2-tasks/new" {{form_mode display} {task_id $opportunity_id}}]
    }  
    if {"im_ticket" == $otype} {
        ad_returnredirect [export_vars -base "/intranet-helpdesk/new" {{form_mode display} {ticket_id $opportunity_id}}]
    }
}

set show_context_help_p 0

set user_id [auth::require_login]
set return_url [im_url_with_query]
set current_url [ns_conn url]

set bgcolor(0) " class=roweven"
set bgcolor(1) " class=rowodd"

if {0 == $opportunity_id} {set opportunity_id $object_id}
if {0 == $opportunity_id} {
    ad_return_complaint 1 "<li>[_ intranet-core.lt_You_need_to_specify_a] "
    return
}

set page_title [lang::message::lookup "" intranet-crm-opportunities.PageTitleViewOpportunity "View Opportunity"]

# ---------------------------------------------------------------------
# Check permissions
# ---------------------------------------------------------------------

# Global admin?
# Only global admins are allowed to "nuke" projects
set site_wide_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]

# get the current users permissions for this project
im_project_permissions $user_id $opportunity_id view read write admin

# Compatibility with old components...
set current_user_id $user_id
set user_admin_p $write

if {![db_string ex "select count(*) from im_projects where project_id=:opportunity_id"]} {
    ad_return_complaint 1 "<li>Project doesn't exist"
    return
}

if {!$read} {
    ad_return_complaint 1 "<li>[_ intranet-core.lt_You_have_insufficient_6]"
    return
}

# ---------------------------------------------------------------------
# Admin Box
# ---------------------------------------------------------------------

set admin_html ""
if {[im_permission $current_user_id "add_projects"]} {
	append admin_html "<li><a href=\"/intranet-crm-opportunities/new\"> [lang::message::lookup "" intranet-crm-opportunities.AddANewOpportunity "New Opportunity"]</a>\n"
}

# ---------------------------------------------------------------------
# Projects Submenu
# ---------------------------------------------------------------------

# Setup the subnavbar
set bind_vars [ns_set create]
ns_set put $bind_vars opportunity_id $opportunity_id
set parent_menu_id [im_menu_id_from_label "project"]
set left_navbar_html ""
if {"" != $admin_html} {
    append left_navbar_html "
      	<div class='filter-block'>
        <div class='filter-title'>[lang::message::lookup "" intranet-crm-opportunities.Opportunities "Opportunities"]</div>
        	<ul>$admin_html</ul>
      	</div>
	<hr/>
    "
}


