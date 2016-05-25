# /packages/intranet-crm-opportunities/www/create-project-from-opportunity.tcl
#
# Copyright (C) 2014 various parties
# The software is based on ArsDigita ACS 3.4
#

# ---------------------------------------------------------------
# 1. Page Contract
# ---------------------------------------------------------------

ad_page_contract {
    Converts Lead to Gantt Project
    @param opportunity
} {
    { opportunity_id 0 }
}

# User id already verified by filters
set user_id [auth::require_login]

# Write Audit Trail
im_audit -object_id $opportunity_id

set sql "
        update
                im_projects
        set
                project_type_id = [im_project_type_gantt],
                opportunity_sales_stage_id = [im_opportunity_sales_stage_closed_won],
                project_status_id = [im_project_status_open],
                start_date = now()::date,
                end_date = now()::date
        where
                project_id = :opportunity_id
"
if {[catch {
    db_dml update_opportunity $sql
} err_msg]} {
    global errorInfo
    ns_log Error $errorInfo
    ad_return_complaint 1  "[lang::message::lookup "" intranet-crm-opportunities.NotAbleToCreateGanttProject "Not able to create Project"] $errorInfo"
    return
}

# Callback 
callback im_opportunity_create_project -opportunity_id $opportunity_id

# User Exit and Audit 
im_user_exit_call project_update $opportunity_id
im_audit -object_type im_project -action after_update -object_id $opportunity_id -status_id [im_project_status_open] -type_id [im_project_type_gantt]

ad_returnredirect "/intranet/projects/view?project_id=$opportunity_id"
