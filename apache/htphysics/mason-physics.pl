package UMPhysDev::Mason;

# Bring in Mason objects
use HTML::Mason;

# Always "use strict" in mod_perl
use strict;

# Force warnings/dies to dump backtrace
#use Carp::Always;

{
package HTML::Mason::Commands;
use vars qw(%session);
use Fcntl;
use IO::File;
use IO::Handle;
use MLDBM;
use Image::Size;
use URI::Escape;
use File::PathConvert;
use File::Spec;
use File::Copy;
use File::Find;
use File::stat;
use Text::Wrap;
use POSIX qw(strftime);
use Date::Language;
use LWP::MediaTypes qw(guess_media_type);
use IPC::Run;
use Rcs;
# needed for new Mason caching...?
use Cache::Cache;
# the rest are additional/local
use Date::Calc qw(:all);
use HTML::FromText;
use HTML::Entities;
use Net::SSLeay;
use IO::Socket::SSL;
use IPC::Open2;
use Apache2::Request;
use Apache2::Upload;
use Apache2::Cookie;
use Apache2::URI;
use DBI;
use Apache2::Const;
use Apache2::RequestUtil;
use Apache2::Connection ();
use Apache2::ServerRec();
use Apache2::ServerUtil ();
use Apache::Session::MySQL;
use Text::Format;
use Convert::ASN1;
use APR::Table;
use APR::Pool ();
use Module::Refresh;
use ShopDb::Schema;
use Data::Dumper;
use physdb;
use Carp qw/carp cluck confess croak/;
# Our mason helper functions like _h and _u
use MasonHelper;
}


# http://www.masonhq.com/docs/manual/Interp.html for docs on this
my %ah;
my $comproot;

# So, this top bit of code is executed once for each new thread of apache that is spawned. It has general setup.

my $s = Apache2::ServerUtil->server;
my $site = $s->dir_config('SiteName');
if ($site eq 'htphysics') {
    warn 'Found htphysics: Setting $comproot to /export/data/web/';
    $comproot = '/export/data/web/';
} else {
    warn "Found $site: Setting \$comproot to /home/www/docs/staging/";
    $comproot = '/home/www/docs/staging/';
}

# This handler is called back for each request.
sub handler
{
    # Get the Apache request object
    my ($r) = @_;
    my $port = $r->get_server_port();

    my $randseed = 384237846234723;
    srand(time + $randseed + $$);

    # Only handle certain types of request (text, html etc); also handle downloads directory (for dhandler)
    return -1 if ($r->uri =~ /^\/(images|static)/) || ($r->content_type && $r->content_type !~ m|^text/|i && $r->uri !~ /download/i) || ($r->filename && ($r->filename =~ m/\.(css|txt|js)$/i ));

    # Refresh modules if on staging site
    if ($site ne 'htphysics') {
        warn "Found site $site: Calling Module::Refresh->refresh()";
        Module::Refresh->refresh();
    }

    # Stateless areas won't have session or login bits performed...
    my $stateless = ($r->uri && $r->uri =~ /^\/stateless/);

    # Get the incoming cookies
    my %cookies;
    eval {
        %cookies = Apache2::Cookie->fetch($r);
    };

    # Determine instance-specific comproot and mason-data locations
    my $this_comproot = $comproot;
    my $data_dir = "/export/data/mason-data/$site";
    my %debug;
    my $cookie_name='UMNPHYS_SESSION_ID';
    if($site ne "htphysics") {
        warn "Found site $site: Checking port $port";
        # Validate the port is in our range
        if(!$port || $port < 4430 || $port > 4460) {
            die("$0 ERROR: Port is set to '$port' but expecting between 4430 and 4460\n");
        }
        $this_comproot .= "$port/";
        %debug = (
            named_component_subs => 0,
            static_source => 0,
            code_cache_max_size => 0,
            use_object_files => 0,
        );
        $cookie_name="UMNPHYS_STAGING_".$port."_SESSION_ID";
    }
    else { #production
        warn "Found site htphysics: Setting \$this_comproot to $this_comproot";
    }

    # Database config - use from $comproot/conf
    my $mycnf = $this_comproot."conf/.my.cnf";
    #$mycnf = "/home/www/.my.cnf" unless (-f $mycnf);
    #warn "Using mycnf of $mycnf";

    my $mycnfgroup = "webdb_test";
    my $database = 'webdb';
    my $session_database = 'websession';
    my $shopdb_database = 'shopdb';

    die("$mycnf not found") unless ( -r $mycnf );

    # Connect to webdb database
    my $dsn = "DBI:mysql:database=$database;mysql_read_default_file=$mycnf;mysql_read_default_group=$mycnfgroup";
    $HTML::Mason::Commands::dbh = DBI->connect_cached($dsn, undef, undef,
        {
            PrintError => 1, # warn() on errors
            RaiseError => 0, # don't die() on error
            AutoCommit => 1, # commit executes immediately
        }
    ) unless (-f "${this_comproot}NODB");

    if ($HTML::Mason::Commands::dbh) {
        $HTML::Mason::Commands::dbh->{'mysql_enable_utf8'} = 1;
    }

    # Ensure physdb is using webdb dbh
    physdb::use_dbh($HTML::Mason::Commands::dbh);

    # Create shopdb schema connection
    my $shopdb_dsn = "DBI:mysql:database=$shopdb_database;mysql_read_default_file=$mycnf;mysql_read_default_group=$mycnfgroup";
    $HTML::Mason::Commands::shopdb->{schema} ||= ShopDb::Schema->connect($shopdb_dsn, undef, undef, { RaiseError => 1, quote_char => '`', name_sep => '.' });

    my $original_x500 = '';
    my $original_physid = '';
    my $session;
    my $session_dbh;

    if (!$stateless) {
        my $session_dsn = "DBI:mysql:database=$session_database;mysql_read_default_file=$mycnf;mysql_read_default_group=$mycnfgroup";

        $session_dbh = DBI->connect_cached($session_dsn, undef, undef,
            {
                PrintError => 1,
                RaiseError => 0,
                AutoCommit => 1,
            }
        );

        # Try to re-establish an existing (cookie) session
        eval {
            tie %HTML::Mason::Commands::session, 'Apache::Session::MySQL',
                ($cookies{$cookie_name} ? $cookies{$cookie_name}->value() : undef),
                {
                 Handle => $session_dbh,
                 LockHandle => $session_dbh,
                };
        };

        # If we could not re-establish an existing, $@ should contain
        # 'Object does not exist in the data store'. If the eval
        # failed for a different reason, that might be important
        if ($@) {
            if ($@ =~ m#^Object does not exist in the data store#) {
                #this will create a new session entry
                tie %HTML::Mason::Commands::session,
                        'Apache::Session::MySQL',
                        undef,
                        {
                              DataSource => $session_dsn,
                              LockDataSource => $session_dsn,
                        };
                undef $cookies{$cookie_name};
            } else {
                #place message in server log
                warn $@;
            }
        }

        if (!$cookies{$cookie_name}) {
            my $cookie = Apache2::Cookie->new($r,
                    -name => $cookie_name,
                    -value => $HTML::Mason::Commands::session{_session_id},
                    -expires => '+36h',
                    -path => '/',
                    -domain => '.umn.edu',
            );
            if (defined($cookie)) {
                warn("Baking a new $cookie_name cookie for client\n");
                $cookie->bake($r);
            }
        }

        # ShibAuth Magic
        # Note: Even when we store the cookie in the session, we still should
        # have a cache. Why...? Currently storing the cookie in the session
        # means it is valid -- if they have an expired/invalid cookie, then
        # every page load it would make a call to the server w/o caching.
        # The other option is obviously to store it in session even if it isn't
        # being used to auth them.
        $session = \%HTML::Mason::Commands::session;
        $original_x500 = ${$session}{'x500'} || '';
        $original_physid = ${$session}{'physid'} || '';

        if (${$session}{'shibauth'} && !$ENV{'HTTPS'}) {
            $HTML::Mason::Commands::session{timestamp}=CORE::localtime;
            untie %HTML::Mason::Commands::session;
            $r->method('GET');
            $r->headers_in->unset('Content-length');
            $r->headers_out->set('Location' => 'https://' . $r->server->server_hostname . $r->uri . '?' . $r->args());
            $r->status(Apache2::Const::REDIRECT);
            return Apache2::Const::REDIRECT;
        }

        my $eppn = (exists $ENV{'eppn'}) ? $ENV{'eppn'} : '';
        if($eppn =~ /^(.+)\@umn\.edu$/) {
            my $new_x500 = $1;
            warn("Found a new x500 at $new_x500\n");
            if ($new_x500 ne $original_x500) {
                warn("Got new x500 from shibboleth eppn. It is $new_x500. Old x500 was $original_x500\n");
                # New or updated login!
                undef(${$session}{'uid'});
                undef(${$session}{'physid'});
                undef(${$session}{'physauth'});
                undef(${$session}{'display_name'});
                ${$session}{'shibauth'} = 1;
                ${$session}{'x500'} = $new_x500;
                my $query = $HTML::Mason::Commands::dbh->prepare('SELECT uid, physid FROM directory WHERE x500=? AND !inactive LIMIT 1');
                $query->execute($new_x500);
                if (my $result = $query->fetchrow_arrayref()) {
                    my ($uid, $physid) = @$result;
                    ${$session}{'physid'} = $physid;
                    ${$session}{'uid'} = $uid;
                }

                my $cookie = Apache2::Cookie->new($r,
                    -name => 'UMNPHYS_PERSIST',
                    -value => 'x500|' . (${$session}{'x500'}||'') . '|' . (${$session}{'physid'}||''),
                    -expires => '+10Y',
                    -path => '/',
                    -domain => '.umn.edu',
                );
                if (defined($cookie)) {
                    $cookie->bake($r);
                }
            }
        }
        elsif (exists( $ENV{'eppn'} )) { # Don't warn unless $ENV{'eppn'} is set
            warn("Unknown format for eppn: $eppn\n");
        }
    } # END !stateless

    # Here we have delayed the creation of the apache handler until after the first request, so we can generate
    # them on the fly, as they are used. This way we can allow for an infinate number of handlers for each svn working
    # copy, without having to pre-load every port. Apache will load them as we need them.
    # Note that the overall environment is inside a short-lived http fork, so the $ah hash will be empty
    # again every few seconds needing re-initialized. Remember that if you plan to do anything fancy below:

    # Setup docroot to the www/ subfolder. Mason needs this to work.
    my $documentroot = $this_comproot."www";
    $r->document_root($documentroot);

    # Now look for an apache handler matching our conditions (port etc). If not found, this is our first
    # request of this child fork. So create one.
    if(!defined $ah{$site}) {
        $ah{$site} = HTML::Mason::ApacheHandler->new(
            comp_root => $this_comproot,
            data_dir => $data_dir,
            args_method => 'mod_perl',
            allow_globals => ['$dbh', '$shopdb'],
            error_mode => 'fatal',
            static_source => 1,
            static_source_touch_file => "$data_dir/reload_source",
            %debug,
        ); # we trap the error ourselves at the bottom
    }

    # Now here wa actually handle the request, using the handler we
    # found/created above. Its eval'd so we can intercept the error.
    my $status = eval  { $ah{$site}->handle_request($r) };
    my $err = $@;

    if (!$stateless) {
        # This updates the extra columns used by PHP and
        # the like so they can use session login...
        #
        # THIS NEEDS TO GO AFTER THE REQUEST TO HANDLE CASES OF WEBSU
        if ($cookies{$cookie_name}) {
            my $address = $r->connection->get_remote_host();
            if (($original_x500 ne (${$session}{'x500'} || '')) || ($original_physid ne (${$session}{'physid'} || ''))) {
                my $query = $session_dbh->prepare('UPDATE sessions SET x500=?, physid=?, address=? WHERE id=?');
                $query->execute(${$session}{'x500'}, ${$session}{'physid'}, $address, $cookies{$cookie_name}->value());
            }
            # Log shibauth logins
            if ($original_x500 ne (${$session}{'x500'} || '') && ${$session}{'shibauth'}) {
                my $query = $HTML::Mason::Commands::dbh->prepare('INSERT INTO auditlog (timestamp, type, user, address, text, user_agent) VALUES (NOW(), ?, ?, ?, ?, ?)');
                $query->execute('login', ${$session}{'x500'}, $address, ${$session}{'x500'}." logged in with shibauth", $ENV{HTTP_USER_AGENT});
            }
        }
    }

    # Timestamp the session hash to ensure Apache::Session writes
    # out the data store The reason for this is that
    # Apache::Session only does a shallow check for changes in
    # %session. If %session contains references to objects whose
    # attributes have changed, those changes won't be recorded. So
    # adding a 'timestamp' key with a value that changes every
    # request ensures that all data structures are stored to disk.
    $HTML::Mason::Commands::session{timestamp}=localtime;

    # The untie statement signals Apache::Session to write any
    # unsaved changes to disk.
    untie %HTML::Mason::Commands::session;

    # error handler...
    if ($err || ($status >= 500 && $status < 600)) {
        $r->pnotes( error => $err );

        # Determine error page
        my $status_file = defined($status) ? $status : '500';
        if ($r->headers_in->{'Accept'} =~ m'text/javascript') {
            $status_file .= '_ajax';
        }
        my $errh = $documentroot . '/errors/' . $status_file . '.html';
        if (!$err && (-e $errh)) {
            $r->filename($errh);
        }
        else {
            if ($r->headers_in->{'Accept'} =~ m'text/javascript') {
                $r->filename($documentroot . '/errors/500_ajax.html');
            }
            else {
                $r->filename($documentroot . '/errors/500.html');
            }
        }

        # Attempt to render error page
        warn "Found site $site: Displaying error $status_file page\n";
        my $errstatus = eval { $ah{$site}->handle_request($r) };
        my $errerr = $@;
        if($errerr) {
            if($site ne "htphysics") {
                # Things are SO broken that the standard template error page can't even display. So just print the error
                # here without a wrapper so at least it can be seen.
                #print("echo Staging Goooo! site: $site<br> comproot: $this_comproot<br> data_dir: $data_dir<br>" . $documentroot);
                print "<h1>Error</h1> There was an error, and /errors/500.html also encountered an error! The error preventing the error handler page from executing is displayed below:";
                my $err_details = $errerr;
                print $err_details->as_html();
                print "<h4>headers:</h4><pre>";
                print Dumper($r->headers_in);
                print "</pre>";
                return($errstatus);
            }
            else {
                print "<h1>Error</h1> There was an error, and /errors/500.html also encountered an error! Very sorry, you found a bug.";
            }
        }
        else {
            # error page executed successfully.
            return $errstatus;
        }
    }
    return $status;
}

1;
