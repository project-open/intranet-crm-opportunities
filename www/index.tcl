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
set page_title [lang::message::lookup "" intranet-crm-opportunities.CRM_Dashboard "CRM Dashboard"]
set context_bar [im_context_bar $page_title]
set return_url [im_url_with_query]

# select the "CRM" Submenu
set parent_menu_sql "select menu_id from im_menus where label='crm'"
set parent_menu_id [util_memoize [list db_string parent_admin_menu $parent_menu_sql -default 0]]


# ---------------------------------------------------------------
# Sub-Navbar
# ---------------------------------------------------------------

set sub_navbar [im_crm_navbar "none" "/intranet-crm-opportunities/index" "" "" [list] "crm_home"] 


# ----------------------------------------------------------
# Build administration links

set admin_html "<ul>"

set links [im_menu_crm_admin_links]
foreach link_entry $links {
    set html ""
    for {set i 0} {$i < [llength $link_entry]} {incr i 2} {
        set name [lindex $link_entry $i]
        set url [lindex $link_entry $i+1]
        append html "<a href='$url'>$name</a>"
    }
    append admin_html "<li>$html</li>\n"
}

# Append user-defined menus
set bind_vars [list return_url $return_url]
append admin_html [im_menu_ul_list -no_uls 1 "crm_admin" $bind_vars]
append admin_html "</ul>"

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
set reports_ctr 0
db_foreach menu_select $menu_select_sql {
    ns_log Notice "im_sub_navbar: menu_name='$name'"
    set name_key [string map {" " "_" "(" "" ")" ""} $name]
    set wrench_url [export_vars -base "/intranet/admin/menus/index" {menu_id return_url}]
    append reports_menu "<li><a href=\"$url\">[lang::message::lookup "" intranet-reporting.$name_key $name]</a>
                               <a href='$wrench_url'>[im_gif wrench]</a></li>
    "
    incr reports_ctr
}
append reports_menu "</ul>"

set left_navbar_html "
	    <div class=\"filter-block\">
		<div class=\"filter-title\">
		    [lang::message::lookup "" intranet-cost.Admin "Administration"]
		</div>
		$admin_html
	    </div>
"
if { 0 != $reports_ctr } {
    append left_navbar_html "
	    <hr/>
	    <div class=\"filter-block\">
		<div class=\"filter-title\">
		    [lang::message::lookup "" intranet-cost.Reports "Reports"]
		</div>
		$reports_menu
	    </div>
    "
}


