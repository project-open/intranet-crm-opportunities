# /packages/intranet-crm-opportunities/www/company-created.tcl
#
ad_page_contract {
    @param new_company_id company_id 
    @author klaus.hofeditz@project-open.com
} {
    new_company_id:integer
}

# ------------------------------------------------------
# Defaults & Security
# ------------------------------------------------------

set user_id [auth::require_login]
