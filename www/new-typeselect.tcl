# /packages/intranet-crm-opportunities/www/new-typeselect.tcl
#
# Copyright (c) 2008 ]project-open[
#

ad_page_contract {
    We get redirected here from the project's "New" page if there
    are DynFields per object subtype and no type is specified.

    @author frank.bergmann@project-open.com
} {
    return_url
    opportunity_id:optional
    { project_name "" }
    { project_nr "" }
    { project_type_id "" }
    { project_customer_id "" }
}

# No permissions necessary, that's handled by the object's new page
# Here we just select an object_type_id for the given object.

set current_user_id [auth::require_login]
set page_title [lang::message::lookup "" intranet-crm-opportunities.Please_Select_Opportunity_Type "Please Select Opportunity Type"]
set context_bar [im_context_bar $page_title]
set user_admin_p [im_is_user_site_wide_or_intranet_admin $current_user_id]

set sql "
	select
		c.category_id,
		c.category,
		c.category_description,
		p.parent_id
	from
		im_categories c
		LEFT OUTER JOIN (select * from im_category_hierarchy) p ON p.child_id = c.category_id
	where
		c.category_type = 'Intranet Project Type' and
		c.category_id != [im_project_type_opportunity] and
		c.category_id in ([join [im_sub_categories [im_project_type_opportunity]] ","])
		-- and (c.enabled_p is null or c.enabled_p = 't')
	order by
		parent_id,
		category
"

# ad_return_complaint 1 "<pre>$sql</pre> <br>[im_ad_hoc_query -format html $sql]"

set category_select_html ""
set old_parent_id ""
db_foreach cats $sql {

    if {$old_parent_id != $parent_id} {
	append category_select_html "<tr><td colspan=2><b>[im_category_from_id $parent_id]</b><br></td></tr>\n"
	set old_parent_id $parent_id
    }

    regsub -all " " $category "_" category_key
    set category_l10n [lang::message::lookup "" intranet-core.$category_key $category]
    set category_comment_key ${category_key}_comment

    set comment $category_description
    if {"" == $comment} { set comment " " }
    set comment [lang::message::lookup "" intranet-core.$category_comment_key $comment]

    append category_select_html "
	<tr>
		<td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>
		<td>
		<nobr>
		<input type=radio name=project_type_id value=$category_id>$category_l10n</input>
		&nbsp;
		</nobr>
		</td>
		<td>$comment</td>
	</tr>
    "

}


set icon_html ""
if {$user_admin_p} {
    set icon_html "<a href='/intranet/admin/categories/index?select_category_type=Intranet+Project+Type'>[im_gif wrench ""]</a>"
}
