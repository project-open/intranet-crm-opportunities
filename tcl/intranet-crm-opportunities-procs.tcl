# /intranet-crm-opportunities/tcl/intranet-crm-opportunities-procs.tcl
#

ad_library {
    @author klaus.hofeditz@project-open.com
    @author frank.bergmann@project-open.com
}

# -----------------------------------------------------------
# Constant Functions
# -----------------------------------------------------------

ad_proc -public im_opportunity_sales_stage_open {} { return 84021} 
ad_proc -public im_opportunity_sales_stage_prospecting {} { return 84010} 
ad_proc -public im_opportunity_sales_stage_qualification {} { return 84011} 
ad_proc -public im_opportunity_sales_stage_needs_analysis {} { return 84012}
ad_proc -public im_opportunity_sales_stage_value_proposition {} { return 84013}
ad_proc -public im_opportunity_sales_stage_id_decision_makers {} { return 84014}
ad_proc -public im_opportunity_sales_stage_perception_analysis {} { return 84015}
ad_proc -public im_opportunity_sales_stage_proposal_price_quote {} { return 84016}
ad_proc -public im_opportunity_sales_stage_negotiation_review {} { return 84017} 
ad_proc -public im_opportunity_sales_stage_closed {} { return 84018} 
ad_proc -public im_opportunity_sales_stage_closed_won {} { return 84019}
ad_proc -public im_opportunity_sales_stage_closed_lost {} { return 84020}

# -----------------------------------------------------------
# Business Logic
# -----------------------------------------------------------

ad_proc -public im_opportunity_base_data_component {
    {-opportunity_id}
    {-return_url}
} {
    returns basic project info with dynfields and hard coded
    Original version from ]po[
} {
    set params [list [list base_url "/intranet-core/"]  [list opportunity_id $opportunity_id] ]
    if { [info exists return_url] } { lappend params [list return_url $return_url] }
    set result [ad_parse_template -params $params "/packages/intranet-crm-opportunities/lib/opportunity-base-data"]
    return [string trim $result]
}


ad_proc -public im_opportunity_pipeline {
    {-diagram_width 300 }
    {-diagram_height 300 }
    {-diagram_caption "" }
} {
    Returns a HTML code with a Sencha diagram showing
    the current opportunities, together with
    presales_probability and presales_value.
} {
    # Sencha check and permissions
    if {![im_sencha_extjs_installed_p]} { return "" }
    im_sencha_extjs_load_libraries

    set params [list \
		    [list diagram_width $diagram_width] \
		    [list diagram_height $diagram_height] \
		    [list diagram_caption $diagram_caption]
    ]

    set result [ad_parse_template -params $params "/packages/intranet-crm-opportunities/lib/opportunity-pipeline"]
    return [string trim $result]
}


ad_proc -public im_opportunity_user_component {
    {-user_id}
    {-number_opportunities_shown 5}
} {
    Returns opportunities a user is a member of 
} {
    set params [list [list user_id $user_id] [list number_opportunities_shown $number_opportunities_shown] ]
    set result [ad_parse_template -params $params "/packages/intranet-crm-opportunities/lib/opportunity-user-data"]
    return [string trim $result]
}

# ----------------------------------------------------------------------
# Navigation Bar
# ---------------------------------------------------------------------

ad_proc -public im_crm_navbar { 
    {-navbar_menu_label "crm"}
    default_letter 
    base_url 
    next_page_url 
    prev_page_url 
    export_var_list 
    {select_label ""} 
} {
    Returns rendered HTML code for a horizontal sub-navigation
    bar for /intranet-crm-opportunities/.
    The lower part of the navbar also includes an Alpha bar.

    @param default_letter none marks a special behavious, hiding the alpha-bar.
    @navbar_menu_label Determines the "parent menu" for the menu tabs for 
    search shortcuts, defaults to "projects".
} {
    # -------- Calculate Alpha Bar with Pass-Through params -------
    set bind_vars [ns_set create]
    foreach var $export_var_list {
	upvar 1 $var value
	if { [info exists value] } {
	    ns_set put $bind_vars $var $value
	}
    }
    set alpha_bar [im_alpha_bar -prev_page_url $prev_page_url -next_page_url $next_page_url $base_url $default_letter $bind_vars]

    # Get the Subnavbar
    set parent_menu_sql "select menu_id from im_menus where label = '$navbar_menu_label'"
    set parent_menu_id [util_memoize [list db_string parent_admin_menu $parent_menu_sql -default 0]]
    
    ns_set put $bind_vars letter $default_letter
    ns_set delkey $bind_vars project_status_id

    set navbar [im_sub_navbar $parent_menu_id $bind_vars $alpha_bar "tabnotsel" $select_label]

    return $navbar
}


ad_proc -public im_menu_crm_admin_links {
} {
    Return a list of admin links to be added to the "crm" menu
} {
    set result_list {}
    set current_user_id [ad_conn user_id]
    set return_url [im_url_with_query]

    if { [im_permission $current_user_id "add_projects"] } {
        # lappend result_list [list [lang::message::lookup "" intranet-crm-opportunities.AddANewOpportunity "Add New Opportunity"] "/intranet-crm-opportunities/new"]
    }
    return $result_list
}

