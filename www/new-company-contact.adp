<%=[im_header -no_head_p 1 -no_master_p 1]%>
<script type="text/javascript">
        $(document).ready(function() {
          $('#new-company-contact').submit(function(e) {
                if (!validateForm()) {
                   e.preventDefault();
                };
          });
         });
         function validateForm() {
                 var validates_p = true;
                  if ($('#first_names').val() == '') {
                    alert('Please provide a value for "First Names"');
                    return false;
                  };
                  if ($('#last_name').val() == '') {
                    alert('Please provide a value for "Last Name"');
                    return false;
                  };
                  var x = document.getElementById('new-company-contact').elements["email"].value;
                  var atpos=x.indexOf('@');
                  var dotpos=x.lastIndexOf('.');
                  if (atpos<1 || dotpos<atpos+2 || dotpos+2>=x.length) {
                     alert('Can\'t create user: Not a valid e-mail address');
                     return false;
                  }
                  $.ajax({
                        type: 'GET',
                        url: '/intranet-crm-opportunities/check-email-exists',
                        data: 'email=' + $('#email').val(),
                        dataType: 'html',
                        async: false,
                        success: function(msg) {
                                 if (msg == '1') {
                                    alert('Can\'t create user: e-mail address already exists');
                                    validates_p = false;
                                 };
                        },
                        error: function(xhr, errorType, exception) {
                               var errorMessage = exception || xhr.statusText;
                               alert('Error validating email. Please logout/login again. Contact your System Administrator if problem persits.' +  errorMessage);
                        }
                });
                return validates_p;
        };
</script>

<formtemplate id="new-company-contact"></formtemplate>
