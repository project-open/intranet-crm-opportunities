# /packages/intranet-crm-opportunities/www/contact-created.tcl
#
ad_page_contract {
    @param new_contact_id contact_id 
    @author klaus.hofeditz@project-open.com
} {
    new_contact_id:integer
}

# ------------------------------------------------------
# Defaults & Security
# ------------------------------------------------------

set user_id [auth::require_login]
