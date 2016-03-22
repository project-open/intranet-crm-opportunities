# /packages/intranet-crm-opportunities/www/index.tcl
#
# Copyright (C) 2003 - 2016 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract {

    CRM Opportunities Landing Page 

    @author frank.bergmann@project-open.com
    @author klaus.hofeditz@project-open.com

} {
}

set current_user_id [auth::require_login]
set page_title [lang::message::lookup "" intranet-crm-opportunities.CRM_Home "CRM Home"]
set context_bar [im_context_bar $page_title]
set return_url [im_url_with_query]

# select the "CRM" Submenu
set parent_menu_sql "select menu_id from im_menus where label='crm'"
set parent_menu_id [util_memoize [list db_string parent_admin_menu $parent_menu_sql -default 0]]


# ---------------------------------------------------------------
# Sub-Navbar
# ---------------------------------------------------------------

set sub_navbar [im_crm_navbar "none" "/intranet-crm-opportunities/index" "" "" [list] "crm_home"] 

# ---------------------------------------------------------------
# Format the admin menu
# ---------------------------------------------------------------

set admin_html ""
if { [im_permission $current_user_id "add_projects"] } {
    append admin_html "<li><a href='[export_vars -base "/intranet-crm-opportunities/new" {return_url}]'>[lang::message::lookup "" intranet-crm-opportunities.AddANewOpportunity "New Opportunity"]</a>\n"
}

set admin_html "<ul>$admin_html</ul>"



# ---------------------------------------------------------------
# Format the Report Creation Menu
# ---------------------------------------------------------------

set parent_menu_sql "select menu_id from im_menus where label = 'reporting-crm'"
set parent_menu_id [util_memoize [list db_string parent_admin_menu $parent_menu_sql -default ""]]

set menu_select_sql "
        select  m.*
        from    im_menus m
        where   parent_menu_id = :parent_menu_id
		and enabled_p = 't'
                and im_object_permission_p(m.menu_id, :current_user_id, 'read') = 't'
        order by sort_order
"

# Start formatting the menu bar
set reports_menu "<ul>"
set ctr 0
db_foreach menu_select $menu_select_sql {
    ns_log Notice "im_sub_navbar: menu_name='$name'"
    set name_key [string map {" " "_" "(" "" ")" ""} $name]
    set wrench_url [export_vars -base "/intranet/admin/menus/index" {menu_id return_url}]
    append reports_menu "<li><a href=\"$url\">[lang::message::lookup "" intranet-reporting.$name_key $name]</a>
                               <a href='$wrench_url'>[im_gif wrench]</a></li>
    "
    incr ctr
}
append reports_menu "</ul>"
set reports_ctr $ctr


set left_navbar_html "
	    <div class=\"filter-block\">
		<div class=\"filter-title\">
		    [lang::message::lookup "" intranet-cost.Admin "Administration"]
		</div>
		$admin_html
	    </div>
	    <hr/>
"


append left_navbar_html "
	    <div class=\"filter-block\">
		<div class=\"filter-title\">
		    [lang::message::lookup "" intranet-cost.Reports "Reports"]
		</div>
		$reports_menu
	    </div>
	    <hr/>
"

