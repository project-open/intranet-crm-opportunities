<master>
<% set admin_p [im_is_user_site_wide_or_intranet_admin [auth::require_login]] %>
<property name="doc(title)">Administration</property>
<property name="admin_navbar_label">admin</property>

    <H2>CRM - User Documentation</H2>
    <ul>
      <li><a href="http://www.project-open.com/en/module-crm" target="_blank">CRM - Module Overview</a>
      <li><a href="http://www.project-open.com/en/company-tutorial" target="_blank">CRM - Company Management</a>
      <li><a href="http://www.project-open.com/en/package-intranet-crm" target="_blank">CRM - Package Documentation</a>
      <li><a href="http://www.project-open.com/en/package-intranet-crm-opportunities" target="_blank">CRM Opportunities - Package Documentation</a>
      <li><a href="http://www.project-open.com/en/process-crm-campaign-management" target="_blank">CRM - Campaign Management Process</a>
<!--
      <li><a href="http://www.project-open.com/en/" target="_blank">CRM - </a>
-->
    </ul>

<if @admin_p@ gt 0>
<!--
    <H2>CRM - Admin Documentation</H2>
    <ul>
      <li><a href="http://www.project-open.com/en/" target="_blank">CRM - </a>
    </ul>
-->


    <H2>CRM - Administration</H2>
    <ul>
      <li><a href="/shared/parameters?package_id=<%= [db_string pid "select package_id from apm_packages where package_key = 'intranet-crm-opportunities'" -default 0] %>" target="_blank">CRM Opportunities - Parameters</a>
      <li><a href="/intranet/admin/categories/index?select_category_type=Intranet+Opportunity+Priority" target="_blank">CRM Opportunities - Priority</a>
      <li><a href="/intranet/admin/categories/index?select_category_type=Intranet+Opportunity+Sales+Stage" target="_blank">CRM Opportunities - Sales Stages</a>
    </ul>

</if>

