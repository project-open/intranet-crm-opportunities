# /packages/intranet-crm-opportunities/lib/opportunity-user-data.tcl
#
# Copyright (C) 2016 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

# ----------------------------------------------------------------------
# Shows a portlet taht lists opportunities the user is a member of
# ---------------------------------------------------------------------

# The following variables are expected in the environment
# defined by the calling /tcl/*.tcl libary:
#	user_id
#       number_opportunities_shown

set bgcolor(0) " class=roweven"
set bgcolor(1) " class=rowodd"
set opportunity_view_page "/intranet-crm-opportunities/view"
set ctr 1

set sql "
        select
		p.project_id as opportunity_id,
                p.project_name as opportunity_name,
		p.company_id,
		(select company_name from im_companies where company_id = p.company_id) as company_name,
                im_category_from_id(p.opportunity_sales_stage_id) as sales_stage,
		to_char(o.creation_date, 'YYYY-MM-DD') as creation_date_formatted
        from
                im_projects p,
                acs_objects o
        where
                p.project_id = o.object_id
                and p.project_type_id = [im_project_type_opportunity]
		and ((
			(p.project_id in (select object_id_two from acs_rels where object_id_one = :user_id) OR p.project_lead_id = :user_id) 
		) OR (
			(p.project_id in (select object_id_one from acs_rels where object_id_two = :user_id and rel_type = 'im_biz_object_member') OR p.company_contact_id = :user_id)
		))
	order by 
		o.creation_date DESC		
	limit 
		:number_opportunities_shown
    "

set component_html "
        <table class=\"table_list_page\">
        <tr class=rowtitle>
          <td class=rowtitle>[lang::message::lookup "" intranet-crm-opportunities.Opportunity "Opportunity"]</td>
          <td class=rowtitle>[lang::message::lookup "" intranet-crm-opportunities.Company "Company"]</td>
          <td class=rowtitle>[lang::message::lookup "" intranet-crm-opportunities.SalesStage "Sales Stage"]</td>
          <td class=rowtitle>[lang::message::lookup "" intranet-crm-opportunities.Created "Created"]</td>
        </tr>
    "

db_foreach opportunity_list $sql {
        append component_html "
                <tr$bgcolor([expr {$ctr % 2}])>
                  <td><a href=\"${opportunity_view_page}?opportunity_id=$opportunity_id\">$opportunity_name</a></td>
                  <td><a href=\"/intranet/companies/view?company_id=$company_id\">$company_name</a></td>
		  <td>$sales_stage</td>
		  <td>$creation_date_formatted</td>
                </tr>
        "
        incr ctr
} if_no_rows {
    append component_html "<tr><td colspan=4>[lang::message::lookup "" intranet-crm-opportunities.NoOpportunitiesFound "No Opportunities Found"]</td></tr>\n"
    }

# Show 'more' link ? 
set sql "
        select 
		count(*)
        from
                im_projects p,
                acs_objects o
        where
                p.project_id = o.object_id
                and p.project_type_id = [im_project_type_opportunity]
		and (p.project_id in (select object_id_two from acs_rels where object_id_one = :user_id) OR p.project_lead_id = :user_id)
    "


if { [db_string get_total_opportunity_members $sql -default 0] > [expr $ctr-1] } {
    append component_html "
        <tr>
          <td colspan=\"99\" align=\"right\">
            <a href=/intranet-crm-opportunities/opportunities?user_id_from_search=$user_id>[_ intranet-core.more_]</a>
          </td>
        </tr>
    "
}

append component_html "</table>"

