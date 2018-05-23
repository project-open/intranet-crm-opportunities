<master>
<property name="doc(title)">@page_title;literal@</property>
<property name="main_navbar_label"></property>

<%= [im_box_header $page_title $icon_html] %>

<form action='@return_url;noquote@' method=POST>
<%= [export_vars -form {return_url opportunity_id project_nr project_name}] %>
<table cellspacing="2" cellpadding="2">

<if "" eq @project_type_id@>
		<tr class=rowodd>
		<td><%= [lang::message::lookup "" intranet-crm-opportunities.Project_type "Project<br>Type"] %></td>
		<td>
			<table>
			@category_select_html;noquote@
			</table>
		</td>
		</tr>
</if>
<else>
	<%= [export_vars -form {project_type_id}] %>
</else>

<tr class=roweven>
    <td></td>
    <td><input type="submit" value='<%= [lang::message::lookup "" intranet-core.Continue "Continue"] %>'></td>
</tr>

</table>
</form>
<%= [im_box_footer] %>

<if @user_admin_p@ gt 0>
<ul>
<li><a href="/intranet/admin/categories/index?select_category_type=Intranet+Project+Type"><%= [im_gif wrench ""] %><%= [_ intranet-crm-opportunities.Admin_project_types] %></a></li>
</ul>

</if>