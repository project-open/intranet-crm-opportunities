<master>
<property name="doc(title)">@page_title;literal@</property>
<property name="context">#intranet-core.context#</property>
<property name="main_navbar_label">crm</property>
<property name="sub_navbar">@crm_navbar_html;literal@</property>
<property name="left_navbar">@left_navbar_html;literal@</property>
<property name="show_context_help">@show_context_help_p;literal@</property>

<form action="/intranet/crm/opportunity-action" method=POST>
      <%= [export_vars -form {return_url}] %>
      <table class="table_list_page">
      	     <%= $table_header_html %>
	     <%= $table_body_html %>
	     <%= $table_continuation_html %>
      </table>
</form>
<br/>


