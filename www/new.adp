<master>
<property name="doc(title)">@page_title;literal@</property>
<property name="main_navbar_label">crm</property>

<script type="text/javascript">
	$(document).ready(function(){
	    
		<if @opportunity_exists_p@ eq "0">
	    	// when page loaded, company is empty, so showing company_contact_id & button makes no sense	    
	    	$('#company_contact_id').attr('disabled', true);
		    $('#btn_loadNewCompanyContact').attr('disabled', true);
	    </if>

	    // Handle cancelation of iframe 'Create new Company'
	    $("#btn_cancel_iframe").click(function(){
	        $("#label_new_company").hide();
	        $("#label_new_company_contact").hide();		
		$("#btn_cancel_iframe").hide();
		$("#html_overlay").hide();
         	$('#div_create_lead :input').attr('disabled', false)
		$('#div_create_lead').stop().animate({opacity : 1}, 300);
                $('#frame_create_new_object').hide();
		// If no company had been choosen, do not allow user to add company contact 
		if ( '' == $('#company_id').val()) {
		    $('#btn_loadNewCompanyContact').attr('disabled', true);
		}
	    });

	    $('#company_id').on('change', function() {
	      	 updateCompanyContactsSelect( $(this).val(),null);
		 if ( '' != $(this).val() ) {
		    $('#company_contact_id').attr('disabled', false);
		    $('#btn_loadNewCompanyContact').attr('disabled', false);
		 } else {
		    $('#company_contact_id').attr('disabled', true);
		    $('#btn_loadNewCompanyContact').attr('disabled', true);
		 };
	    });
	    $("#html_overlay").hide();
    
	    <if @validation_error_p@ eq 1>
	    	// alert('validation_error');
		    <if @company_id@ nil>
		    	$("#label_new_company").show();
		    </if>
		    <if @company_contact_id@ not nil and @company_id@ not nil>
	    		//alert('company_contact_id not nil:' + @company_contact_id@ );
		    	// company_contact_id had been set already 
			    $('#company_contact_id').attr('disabled', false);
			    $('#btn_loadNewCompanyContact').attr('disabled', false);
	    		updateCompanyContactsSelect(@company_id@,@company_contact_id@);
	    	</if>
	    	<if @company_contact_id@ nil and @company_id@ not nil>
	    		$('#company_contact_id').attr('disabled', false);	    
			    $('#btn_loadNewCompanyContact').attr('disabled', false);
	    		updateCompanyContactsSelect(@company_id@,null);			    
	    	</if>
	    </if>
	});

function loadNewCompanyContactIFrame() {
	 // Loads the iframe to create a new company contact 
	 $('#frame_create_new_object').show();
	 $('#div_create_lead :input').attr('disabled', true);
	 $('#div_create_lead').stop().animate({opacity : 0.5}, 300);
	 $("#label_new_company_contact").show();
         $("#btn_cancel_iframe").show();
	 $("#html_overlay").show();
	 var el = document.getElementById('frame_create_new_object');
	 el.src = '/intranet-crm-opportunities/new-company-contact?company_id=' + $("#company_id").val();
}

function loadNewCompanyIFrame() {
	 // Loads the iframe to create a new company 
	 $('#div_create_lead :input').attr('disabled', true);
	 $('#div_create_lead').stop().animate({opacity : 0.5}, 300);
	 $("#label_new_company").show();
	 $("#btn_cancel_iframe").show();
	 $("#html_overlay").show();
	 $('#frame_create_new_object').show();
	 var el = document.getElementById('frame_create_new_object');
	 el.src = '/intranet/companies/new?show_master_p=0&return_url=/intranet-crm-opportunities/company-created&company_type_id=' + $("#company_type_id").val();
}

// called when new Company has been created in iframe
function removeNewCompanyIframe(new_company_id) {
	 // console.log('removeNewCompanyIframe -> new_company_id:' + new_company_id);
	 // removes the iframe and triggers all consecuitive actions
         $("#label_new_company").hide();
         $("#btn_cancel_iframe").hide();
         $("#html_overlay").hide();
         $('#div_create_lead :input').attr('disabled', false)
         $('#div_create_lead').stop().animate({opacity : 1}, 300);
         resetIFrame();
	 // get company_name of company we have just created 
	 $.ajax({
		type: "GET",
		url: "/intranet-rest/im_company/" + new_company_id,
		data: "format=json",
		contentType: "application/json; charset=utf-8",
		dataType: "json",
		success: function(msg) {

			// Hide Button "Create new company"
			$('#btn_loadNewCompany').hide();

			// setting the span containing the company_name
			$('#company_name').html(msg['data'][0]['company_name'] + '&nbsp;');

			// Even though disabled, we use this element to hold the current company_id. Add option, select it and hide element												   
			$('#company_id').append('<option value=' + new_company_id + '>' + msg['data'][0]['company_name'] + '</option>');
			$('#company_id').val(new_company_id);
			$('#company_id').hide();

			// if a new company have been created we disable the input 'company_contact_id' and remove existing options
			$('#company_contact_id').attr('disabled', true);
			$('#company_contact_id').find('option').remove().end();
			$('#company_contact_id').append('<option value=""></option>');   
			
   		},
		error: function(err) {
		       alert('Error reading Company' + err.toString());
		       if (err.status == 200) {
	                 ParseResult(err);
		       } else { 
		       	 alert('Error:' + err.responseText + '  Status: ' + err.status); 
		       }
    	        }
	});
}

// called when new user has been created in iframe
function removeNewUserIframe(user_id) {
	 // console.log('removeNewUserIframe - user_id:' + user_id);
	 $('#title_new_user').hide();
	 $('#label_new_company_contact').hide();
	 $('#btn_cancel_iframe').hide();
	 $("#html_overlay").hide();
	 $('#div_create_lead :input').attr('disabled', false);
	 $('#div_create_lead').stop().animate({opacity : 1}, 300);
         resetIFrame();
	 updateCompanyContactsSelect($('#company_id').val(), user_id);
	 // console.log('set company_contact_id to:' + user_id);
}

function updateCompanyContactsSelect(company_id, val_selected) {
	// implemented based on existing code (intranet-invoice/www/new.tcl)
	// Can be improved 
         $.ajax({
                type: "GET",
                url: "/intranet/users/ajax-company-contacts?user_id=@user_id;noquote@&auto_login=@auto_login;noquote@&company_id=" + company_id,
                success: function(msg) {
			// Remove all existing elements and add empty option 
			$('#company_contact_id').find('option').remove().end();
			$('#company_contact_id').append('<option value=""></option>');
			// Add options					
			if ( '' != msg) {
			   var opts1 = msg.split("|");
			   for (i=0; i < opts1.length; i = i+2) {
			       if ( val_selected == $.trim(opts1[i]) ) {
			              $('#company_contact_id').append('<option selected value="' + $.trim(opts1[i]) + '">' + opts1[i+1] + '</option>');			       	  
			       } else {
			              $('#company_contact_id').append('<option value="' + $.trim(opts1[i]) + '">' + opts1[i+1] + '</option>');			       	  
			       };
			   };
			};
                },
                error: function(err) {
                       alert('error');
                       // alert(err.toString());
                       if (err.status == 200) {
                         ParseResult(err);
                       } else {
                         alert('Error:' + err.responseText + '  Status: ' + err.status);
                       }
                }
        });
}

function resetIFrame() {
	 var frame = document.getElementById('frame_create_new_object');
	 frameDoc = frame.contentDocument || frame.contentWindow.document;
	 frameDoc.documentElement.innerHTML = "";
}

</script>

<section style="width: 100%; margin: 0 auto;overflow: hidden;">
  <div style="float:left;margin-right:20px">
    <h2><%=[lang::message::lookup "" intranet-crm-opportunities.CreateNewLead "New Lead"]%></h2>
    <span id="div_create_lead"><formtemplate id="@form_id@"></formtemplate></span>
  </div>
  <div id="html_overlay" style="overflow: hidden;display: block;border-style:dotted">
    <table cellpadding="0" cellspacing="0" border="0" width="100%">
        <tr>
                <td align="right" valign="top">
                    <a id="btn_cancel_iframe" onmouseover="" style="display:none;cursor:pointer;text-decoration:underline"><%=[lang::message::lookup "" intranet-crm-opportunities.Cancel "Cancel"]%></a>
                </td>
        </tr>
        <tr>
                <td valign="top">
                    <h2 id="label_new_company" style="display: none"><%=[lang::message::lookup "" intranet-crm-opportunities.CreateNewCompany "Create new Company"]%></h2>
                    <h2 id="label_new_company_contact" style="display: none"><%=[lang::message::lookup "" intranet-crm-opportunities.CreateNewCompanyContact "Create new Company Contact"]%></h2><br/>
                    <iframe id='frame_create_new_object' style='margin: 0;padding: 0;border: none;width: 100%;height:1000px'>
                </td>
        </tr>
  </div>
</section>
