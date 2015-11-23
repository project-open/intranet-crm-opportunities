# /packages/intranet-crm-opportunities/www/check-email-exists.tcl
#
# Copyright (C) 2014 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract {
    @param email email 
    @author klaus.hofeditz@project-open.com
} {
    email
}

# ------------------------------------------------------
# Defaults & Security
# ------------------------------------------------------

set user_id [auth::require_login]

if {[catch {
    ns_return 200 text/html [db_string get_data "select count(*) from parties where email=:email" -default -1]
} err_msg]} {
    ns_return 500 text/html -1 
}


