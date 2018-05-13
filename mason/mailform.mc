<%doc>
Overview
--------

This component deals with the ubiquious HTML2Mail problem: A web user fills
out a form (giving away details and request information) and submits the form.
The component will analyse the fields, do some sanity checks and fires off
an email.

Components
----------

The only important component is mailform.mc (I use the extension .mc for
Mason components here). The other components are just for demonstration
purposes:

   - testform.mc: A sample FORM to demonstrate how the fields could look like.

   - success.mc: can be accessed when the form parameters have passed all checks,
                 mailform.mc will serve as a fallback.

   - failure.mc: can be accessed when some checks failed, mailform.mc will serve
                 as a fallback.

   - templates/generic.mail: A generic (nomen est omen) template for the
                 mails to be sent.

Form Fields
-----------

To control this, the FORM may contain the following fields (see testform.mc):

  o Data fields follow the pattern 

       \d+_<name>(_default)?(_required)?(_<type>)?

    - The number in front should help sorting the fields later in templates.
    - The <name> of the field identifies the field later in templates. The name
      cannot contain any '_' characters.

      A field name '03_email_required_email' can be addressed as '03_email' in
      the templates.

    - The <type> can be any of

       text         .*
       numeric      [0-9\.]+
       email        xxxx@yyy.dom (with yyy.dom having an MX record)
       phone        [0-9+-\s]+

      and will be checked by the component.

    - If '_default' is appended, then the value of this field will be taken
      as default value. So if, for example, in

        <INPUT TYPE="TEXT" NAME="04_information">

      the user provided no value, then according to

        <INPUT TYPE="HIDDEN" NAME="04_information_default" VALUE="product range">

      the component will insert 'product range' for '04_information'.

      [ You can also provide defaults within the component configuration if you
        worry about users manipulating forms. ]

    - If '_required' is appended, it will also be checked whether the field
      contains any value.

  o Mail header fields: It is also possible to set the mail headers in the mail to be sent.
    This is done via fields of the form

        _header_<mail_header>

    where <mail_header> stands for the mail header field like 'To', 'Cc', 'Subject', et.al.
    As this has its risk, the config allows you to define the acceptable headers ('valid_header_fields').

  o Template fields: In case you chose to trust these fields, see config documentation, they 
    define which other documents (maybe again Mason components are supposed to be 'called' 
    in case of success (or failure) of the checks. 'Calling' here means 'being redirected to', 
    so the component returns a 302 code to the client together with the next URL and also all 
    relevant parameters.

    The two fields controlling which URL to go to are:

       _template_success
       _template_failure

    Both can be relative URIs but also absolute URLs. While this is pretty flexible, it
    might also be exploited by bad people out there although the harm is limited.

    To control which template for the mail itself should be used, the field

       _template_mail

    can be used, if the method specified in the configuration honors this.

Field Values
------------

Sometimes it is convenient to retrieve a value of a particular field
from another one (like in the testform.mc). This can be done by referencing:

  <INPUT TYPE="TEXT"   NAME="02_email_required_email" VALUE="rumsti@ramsti.com">
  <INPUT TYPE="HIDDEN" NAME="_header_To"              VALUE="ref_02_email">

The component will (before any checks) fill '_header_To' with 'rumsti@ramsti.com'.
Referencing works over any number of redirections. If a reference points to a
non-existing field, the value will be undef.

Installation & Configuration
----------------------------        

  - install required CPAN modules:

       Email::Valid
       URI
       Mail::Mailer

  - copy this component somewhere into your document tree.

  - clone your form from the testform.mc (can be a normal HTML page as
    well) and point the ACTION to the mailform.mc. Test whether this
    link works. You can set $config->{debug} (in the <%once> section to 1.
    You should see a dump of

      - the original fields from the forms
      - the fields how the component has resolved them
      - the list of error messages

    No mail is sent and no redirection is done.

  - Setup response pages for success and/or failure and decide whether they should
    be set via the FORM or via the component or should be fixed (see configuration 
    below). These pages can be pure HTML or Mason components. success.mc and 
    failure.mc might be of help here.

    In the success case, all relevant data fields are handed over. In the case
    of a failure, the messages are sent along.

Author
------

rho@telecoma.net

Credits
-------

The design was heavily influenced by the infamous mailform.pl by cm@ping.at.

</%doc>

% if ($config->{debug}) {
<PRE>
<% Data::Dumper(%ARGS) %>
<% Data::Dumper(%fields) %>
<% Data::Dumper(%msgs) %>
</PRE>
% }


% if (%msgs) {
Folgende Eingabefehler wurden entdeckt:

<UL>
% foreach (keys %msgs) {
    <LI><%$msgs{$_}%>
% }
</UL>

    Bitte gehen Sie zur&uuml;ck, um die Fehler zu beheben.

% } else {
    Danke, Ihre Anfrage wurde weitergeleitet.
% }

<%once>
use Email::Valid;
use URI;
use Mail::Mailer qw(sendmail);

my $applications  # see config below
  = { 1 => { mail    => 'templates/generic.mail',
	     success => 'success.mc',
	     failure => 'failure.mc' },
#     2 => { ... }
    };

my $config = {
# I love debugging code
              debug    => 0,
# here you can hard code any default values for input fields
	      defaults => {# '07_something' => '42',
			   # '04_name' => 'ramstimausi'
			  },
# here you specify a list of mail headers which you allow to be set via form fields
	      valid_header_fields => [ qw (To Cc Subject Reply-To) ],
# to avoid that this script is activated from any server, you might want to
# restrict it to specific patters
#             acceptable_referrers => [ 'http://www.foo.bar/myforms/' ],
              acceptable_referrers => undef,  # means no check
# this routine computes the name of the (mail/html) templates
# adapt it to your security policy
#    Method A: only one (generic) template
     #        mail_template    => sub { return "templates/generic.mail" },
     #        success_template => sub { return 'success.mc' }
     #        success_template => sub { return 'failure.mc' }
#    Method B: trust what comes from the browser (argh)
     #        mail_template    => sub { my %args = @_; return "templates/".$args{_template_mail} },
     #        success_template => sub { my %args = @_; return $args{_template_success} }
     #        success_template => sub { my %args = @_; return $args{_template_success} }
#    Method C: browser only sends id of the 'application' and we dispatch here
#              this is a bit more secure
              mail_template => sub { 
     		my %args = @_; 
     		return $applications->{$args{_dispatch_id}}->{mail} } ,
	      success_template => sub { 
     		my %args = @_; 
     		return $applications->{$args{_dispatch_id}}->{success} },
	      failure_template => sub { 
     		my %args = @_; 
     		return $applications->{$args{_dispatch_id}}->{failure} }
	     };
</%once>

<%init>
## check from where we come from
if ($config->{acceptable_referrers}) {
   die "Inacceptable referrer '$ENV{HTTP_REFERER}'" 
     unless grep ($ENV{HTTP_REFERER} =~ /^$_/i, @{$config->{acceptable_referrers}});
}


my %msgs;

## collect fields and headers
my %fields;
foreach my $arg (keys %ARGS) {
  if ($arg =~ /^(\d+_[^_]+(_default)?)(_required)?(_([^_]+))?$/) {
    $fields{$1} = 
      { name       => $1,
	fullname   => $arg,
	type       => $5,
	is_default => defined $2,
	required   => defined $3,
	value      => $ARGS{$arg}}
  } elsif ($arg =~ /^_header_(.*)/) {
    $fields{ucfirst($1)} = 
      { name       => $1,
	fullname   => $arg,
	type       => 'header',
	value      => $ARGS{$arg} };
  } elsif ($arg =~ /^_template_(.*)/) {
    $fields{$1} = 
      { name       => $1,
	fullname   => $arg,
	type       => 'template',
	value      => $ARGS{$arg} };
  }
}

## resolve indirection
foreach my $f (keys %fields) {
  while ($fields{$f}->{value} =~ /^ref_(.+)/) {
    $fields{$f}->{value} = $fields{$1}->{value};
  }
}

## apply form defaults
foreach my $f (grep ($fields{$_}->{is_default}, keys %fields)) {
  if ($f =~ /^(.+?)_default/) {
    $fields{$1}->{value} ||= $fields{$f}->{value};
  }
}

## apply config defaults
foreach my $f (keys %{$config->{defaults}}) {
  $fields{$f}->{value} ||= $config->{defaults}->{$f};
}

## test required
foreach my $f (grep ($fields{$_}->{required}, keys %fields)) {
  $msgs{$f} = "Required valued for '$f' is missing." unless $fields{$f}->{value};
}

## check type constraints
foreach my $f (grep ($fields{$_}->{type}, keys %fields)) {
  if ($fields{$f}->{type} eq 'text') { # ignore
  } elsif ($fields{$f}->{type} eq 'numeric') {
    $msgs{$f} = "Das Feld '$f' hat keinen numerischen Wert ('$fields{$f}->{value}')" 
      unless $fields{$f}->{value} =~ /^[0-9\.]+$/;
  } elsif ($fields{$f}->{type} eq 'email') {
    $msgs{$f} = "Das Feld '$f' enth&auml;lt keine g&uuml;ltige Email Adresse(n) ('$fields{$f}->{value}')" 
      unless Email::Valid->address(-address => $fields{$f}->{value},
				   -mxcheck => 1 );
  } elsif ($fields{$f}->{type} eq 'phone') {
    $msgs{$f} = "Das Feld '$f' hat keine g&uuml;ltige Telephonnummer ('$fields{$f}->{value}')" 
      unless $fields{$f}->{value} =~ /^[0-9\+\-\s]+$/;
  } 
}

## test headers
foreach my $f (grep ($fields{$_}->{header}, keys %fields)) {
  if (grep (/^$f$/i, qw (To Cc Bcc))) {
    $msgs{$f} = "Ung&uuml;ltige Email Adresse(s) '$fields{$f}->{value}' f&uuml;r '$1' " if
      map { Email::Valid->address( -address => $_, -mxcheck => 1 ) ? () : 1 } split /,/, $fields{$f}->{value};
  }
  # suppress suspicious fields
  delete $fields{$f} unless $fields{$f} && grep (/^$f$/, @{$config->{valid_header_fields}});
}


unless (%msgs) {
  # calling the configuration to figure out the mail template
  my $mail_template = &{$config->{mail_template}} (%ARGS);
  my %headers       = %{$m->comp("$mail_template:headers")};
  foreach my $h (keys %headers) { # overrule was has been coming from the FORM
    $fields{$h}->{value} = $headers{$h};
  }

  unless ($config->{debug}) {
    my $mailer = new Mail::Mailer 'sendmail';
    $mailer->open(\%headers);
    print $mailer $m->scomp ($mail_template, %ARGS);
    $mailer->close;
  }

  my $t = &{$config->{success_template}} (%ARGS);

  if (!$config->{debug} && $t) {
    my $thisurl = URI->new('http://'.$r->server->server_hostname.$r->uri);
    my $nexturl = URI->new_abs($t, $thisurl);
    $nexturl->query_form ( map { $_ => $fields{$_}->{value} } grep ($fields{$_}->{name} =~ /^\d/, keys %fields) );
    $r->send_cgi_header("Location: $nexturl\n\n");
    return;
  } # else show this with a friendly default message
} else {
  my $t = &{$config->{failure_template}} (%ARGS);

  if (!$config->{debug} && $t) {
    my $thisurl = URI->new('http://'.$r->server->server_hostname.$r->uri);
    my $nexturl = URI->new_abs($t, $thisurl);
#    $nexturl->query_form ( map { $_ => $fields{$_}->{value} } grep ($fields{$_}->{name} =~ /^\d/, keys %fields) );
    $nexturl->query_form ( %msgs  );
    $r->send_cgi_header("Location: $nexturl\n\n");
    return;
  } # else show some error messages
}
</%init>
