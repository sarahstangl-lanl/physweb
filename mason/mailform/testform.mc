<HEAD>
</HEAD>
<BODY>

<H3>Demonstration Forms</H3>

<HR>
This form asks for 'name' and 'email'. It uses hidden fields to control the
templates for the success (all checks ok) and failure cases. Another hidden
field controls directly the mail template to be used for send email (see
the discussion in the component about doing this).

<FORM ACTION="mailform.mc">
name (required): <INPUT TYPE="TEXT" NAME="01_name_required" VALUE="rumsti"><BR>
email (required): <INPUT TYPE="TEXT" NAME="02_email_required_email" VALUE="">
<P>

<INPUT TYPE="HIDDEN" NAME="02_email_default" VALUE="rumsti@yahoom.com">
&lt;INPUT TYPE="HIDDEN" NAME="02_email_default" VALUE="rumsti@yahoom.com"&gt;
<p>
<INPUT TYPE="HIDDEN" NAME="_header_To" VALUE="ref_02_email">
&lt;INPUT TYPE="HIDDEN" NAME="_header_To" VALUE="ref_02_email&gt;
<p>
<INPUT TYPE="HIDDEN" NAME="_header_Subject" VALUE="Luschtig">
&lt;INPUT TYPE="HIDDEN" NAME="_header_Subject" VALUE="Luschtig"&gt;

&lt;INPUT TYPE="HIDDEN" NAME="_template_success" VALUE="success.mc"&gt;
<INPUT TYPE="HIDDEN" NAME="_template_success" VALUE="success.mc">
<p>
&lt;INPUT TYPE="HIDDEN" NAME="_template_failure" VALUE="failure.mc"&gt;
<INPUT TYPE="HIDDEN" NAME="_template_failure" VALUE="failure.mc">
<p>

<INPUT TYPE="HIDDEN" NAME="_template_mail" VALUE="generic.mail">


<INPUT TYPE="SUBMIT">
</FORM>

<HR>
The second form uses the 'application' approach instead of allowing the
form to control things:

<FORM ACTION="mailform.mc">
name (required): <INPUT TYPE="TEXT" NAME="01_name_required" VALUE="rumsti"><BR>
email (required): <INPUT TYPE="TEXT" NAME="02_email_required_email" VALUE="">
<P>
<INPUT TYPE="HIDDEN" NAME="02_email_default" VALUE="rumsti@yahoom.com">
&lt;INPUT TYPE="HIDDEN" NAME="02_email_default" VALUE="rumsti@yahoom.com"&gt;
<p>

<INPUT TYPE="HIDDEN" NAME="_dispatch_id" VALUE="1">
&lt;INPUT TYPE="HIDDEN" NAME="_dispatch_id" VALUE="1"&gt;

<INPUT TYPE="SUBMIT">
</FORM>

End of Fun.

</BODY>