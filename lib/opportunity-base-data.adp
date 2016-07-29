<table border="0">
<tbody>
  <tr> 
    <td><%=[lang::message::lookup "" intranet-crm-opportunities.OpportunityName "Name"]%></td>
    <td>@project_name;noquote@</td>
  </tr>
  <tr> 
    <td><%=[lang::message::lookup "" intranet-crm-opportunities.OpportunityNumber "Number"]%></td>
      <td>@project_nr;noquote@</td>
  </tr>
  @im_company_link_tr;noquote@
  <tr>
    <td><%=[lang::message::lookup "" intranet-crm-opportunities.CompanyContact "Company Contact"]%></td>
    <td>@im_render_company_contact_id;noquote@</td>
  </tr>
  <tr> 
    <td><%=[lang::message::lookup "" intranet-crm-opportunities.OpportunityOwner "Owner"]%></td>
    <td>@im_render_user_id;noquote@</td>
  </tr>
  <tr>
    <td><%=[lang::message::lookup "" intranet-crm-opportunities.Created "Created"]%></td>
    <td>@creation_date;noquote@</td>
  </tr>
  <if @project_dynfield_attribs:rowcount@ gt 0>
    <multiple name="project_dynfield_attribs">
      <if @project_dynfield_attribs.value@ not nil>
      <tr>
        <td>@project_dynfield_attribs.attrib_var;noquote@</td>
        <td>@project_dynfield_attribs.value;noquote@</td>
      </tr>
      </if>
    </multiple>
  </if>
  <if @write@ and @edit_project_base_data_p@>
    <tr> 
      <td>&nbsp; </td>
      <td> 
        <form action="/intranet-crm-opportunities/new" method="POST">
	  <input type="hidden" name="return_url" value="@return_url@">
	  <input type="submit" value="#intranet-core.Edit#" name="submit3">
	  <input type="hidden" name="opportunity_id" value="@opportunity_id@">
        </form>
      </td>
    </tr>
  </if>
</tbody>
</table>
