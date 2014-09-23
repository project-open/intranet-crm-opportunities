# /packages/intranet-crm-opportunities/www/create-project-from-opportunity.tcl
#
# Copyright (C) 2014 various parties
# The software is based on ArsDigita ACS 3.4
#

# ---------------------------------------------------------------
# 1. Page Contract
# ---------------------------------------------------------------

ad_page_contract {
    Converts Lead to Consulting Project
    @param opportunity
} {
    { opportunity_id 0 }
}

# ---------------------------------------------------------------
# 1. Defaults & Security
# ---------------------------------------------------------------

# User id already verified by filters
set user_id [ad_maybe_redirect_for_registration]
set admin_p [im_is_user_site_wide_or_intranet_admin $user_id]

set sql "
        update
                im_projects
        set
                project_type_id = 2501,
                opportunity_sales_stage_id = [im_opportunity_sales_stage_closed_won],
                project_status_id = [im_project_status_open],
                start_date = now()::date,
                end_date = now()::date
        where
                project_id = :opportunity_id
"
if {[catch {
    db_dml target_languages $sql
} err_msg]} {
    global errorInfo
    ns_log Error $errorInfo
    ad_return_complaint 1  "[lang::message::lookup "" intranet-crm-opportunities.NotAbleToCreateConsultingProject "Not able to create Project"] $errorInfo"
    return
}

ad_returnredirect "/intranet/projects/view?project_id=$opportunity_id"