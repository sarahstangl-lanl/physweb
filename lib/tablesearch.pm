package Tablesearch;

use warnings;
use strict;
use DBI;
use Exporter qw(import);
use Tablesearch::Data::DBI;
use Tablesearch::Data::DBIC;
use Tablesearch::Output::HTML;
use Tablesearch::Output::Excel;
use Tablesearch::Output::Array;
use HTML::Entities;

my %default_args = (
    # These should be passed in as args to the component
    'ajax' => undef,
    'ajax_parameters' => undef,
    'ajax_url' => undef,
    'ajax_pre_callback' => undef,
    'ajax_post_callback' => undef,
    'column_fetch_format' => 'NAME_lc',
    'data' => undef,
    'data_format' => undef,
    'data_wrapper' => undef,
    'data_wrapper_form' => undef,
    'dbh' => undef,
    'default_sort_dir' => undef,
    'default_sort_field' => undef,
    'excel_filename' => 'export',
    'excel_handle_dates' => 1,
    'excel_link' => 0,
    'excluded_search_fields' => undef,
    'extra_url_args' => undef,
    'field_list' => undef,
    'field_params' => undef,
    'filter_field' => undef,
    'filter_groups' => undef,
    'filter_join' => undef,
    'filter_name_field' => undef,
    'filter_search_name' => undef,
    'filter_values' => undef,
    'group_by' => undef,
    'header_format' => undef,
    'hide_header' => undef,
    'hide_pagenator' => undef,
    'hide_search' => undef,
    'html_table_id' => undef,
    'include_hidden' => 0,
    'joins' => undef,
    'no_limit' => 0,
    'no_sort' => 0,
    'no_header_wrap' => 0,
    'no_form' => 0,
    'pathquery' => 0,
    'postdata' => undef,
    'postrow' => undef,
    'prefix' => '',
    'prerow' => undef,
    'quote_char' => '`',
    'require_field_auth' => undef,
    'resultset' => undef,
    'row_tagger' => undef,
    'search_fields' => undef,
    'show_remaining_columns' => 0,
    'sort_prefix_field' => '',
    'sort_prefix_dir' => '',
    'sql' => undef, # No ORDER BY or LIMIT (handled by tablesearch)
    'storage_engine' => 'mysql',
    'table' => undef,
    'where' => '',

    # Set to 1 to print generated SQL query and args
    'debug' => 0,

    # Set to 1 to allow SQL injection
    'insecure' => 0,

    # Setting this can make some queries MUCH faster, some queries slower,
    # but can also BREAK QUERIES (it's our fault. It happens when using aliased columns in WHERE or ORDER)
    # SQL_CALC_FOUND_ROWS possible horribleness: http://bugs.mysql.com/bug.php?id=18454
    'no_calc_found_rows' => 0,

    # These are set by the search form
    'limit' => 20,
    'start' => 0,
    'sort' => '',
    'sort_reverse' => undef,
    'page' => 0,
    'search' => '',
    'filter' => '',
    'columns' => undef,
    'show_all' => '', # Use no_limit for component arg
);

# Engine-specific settings
my %engine_default_args = (
        'mysql' => {
            'quote_char' => '`',
        },
        'oracle' => {
            'quote_char' => '"',
            'no_calc_found_rows' => 1,
        },
);

sub new
{
    my $class = shift;
    my %args = @_;
    my %defaults = %default_args;

    if (exists($args{storage_engine})) {
        my $storage_engine = $args{storage_engine};
        die "Invalid storage engine " . $storage_engine unless (exists($engine_default_args{$storage_engine}));
        %defaults = (%defaults, %{$engine_default_args{$storage_engine}});
    }

    my %meow = (%defaults, %args);

    my $self = \%meow;

    bless($self, $class);

    $self->import_request_args;

    $self->sanitize_request_args;

    $self->validate_args;

    return $self;
}

sub validate_args
{
    my $self = shift;

    if ($self->{sql}) {
        my $sql_warn = sub { my $arg = shift; warn "$arg argument not allowed when specifying sql query (\$ts->{sql})"; };
        if ($self->{search}) {
            $sql_warn->('Search');
            $self->{search} = undef;
        }
        if ($self->{filter}) {
            $sql_warn->('Filter');
            $self->{filter} = undef;
        }
    }
    unless (defined $self->{table} || defined $self->{data} || defined $self->{resultset} || defined $self->{sql}) {
        die "table, data, sql, or resultset is required";
    }
    # These not defined causes string warnings
    for my $var (qw/prefix sort filter/) {
        $self->{$var} ||= '';
    }
}

sub sanitize_request_args
{
    my $self = shift;

    # If we have a field list and our sorting field isn't in it, revert to defaults
    if ($self->{sort}) {
        my @valid_order_fields = defined($self->{field_list}) ?
                map {
                    my $field = $_;
                    $field =~ s/^.* as //is;
                    $field =~ s/.*\.(.*)/$1/i;
                    $self->clean_sql($field);
                } @{$self->{field_list}} :
                ( );
        if (@valid_order_fields && ! grep { $_ eq $self->{sort} } @valid_order_fields) {
            $self->{sort} = $self->{default_sort_field};
            $self->{sort_order} = $self->{default_sort_dir};
        }
    }

    if(defined($self->{default_sort_field}) && !$self->{sort}) {
        $self->{sort} = $self->{default_sort_field};
    }
    if(defined($self->{default_sort_dir}) && !defined($self->{sort_reverse})) {
        $self->{sort_reverse} = uc($self->{default_sort_dir}) eq 'ASC' ? 0 : 1;
    }

    if($self->{limit} < 1) {
        $self->{limit} = 20;
    }

    if($self->{page} != 0) {
        $self->{start} = ($self->{page} - 1)*$self->{limit};
    }

    if($self->{sort_reverse}) {
        $self->{sort_order} = "DESC";
    } else {
        $self->{sort_order} = "ASC";
    }

    if($self->{filter_field}) {
        $self->{filter} = 'all' unless ($self->{filter} ne '');
    }
    else {
        $self->{filter} = undef;
    }
}

sub sql_ident_sanitize
{
    my ($self, $in) = @_;

    $in =~ s/[^\w]//g;

    return $in;
}

sub clean_sql
{
    my ($self, $sql) = @_;
    $sql =~ s/\Q$self->{quote_char}\E//g;
    return $sql;
}

sub import_request_args
{
    my $self = shift;
    my $request_args = shift;

    if (!$request_args && HTML::Mason::Request->can('instance')) { $request_args = HTML::Mason::Request->instance->request_args; }

    return unless ($request_args);

    if(defined($request_args->{$self->{prefix}.'limit'})) { $self->{limit} = int($request_args->{$self->{prefix}.'limit'}); }
    if(defined($request_args->{$self->{prefix}.'start'})) { $self->{start} = int($request_args->{$self->{prefix}.'start'}); }
    if(defined($request_args->{$self->{prefix}.'sort'})) { $self->{sort} = $request_args->{$self->{prefix}.'sort'}; }
    if(defined($request_args->{$self->{prefix}.'sort_reverse'})) { $self->{sort_reverse} = $request_args->{$self->{prefix}.'sort_reverse'}; }
    if(defined($request_args->{$self->{prefix}.'page'})) { $self->{page} = int($request_args->{$self->{prefix}.'page'}); }
    if(defined($request_args->{$self->{prefix}.'search'})) { $self->{search} = $request_args->{$self->{prefix}.'search'}; }
    if(defined($request_args->{$self->{prefix}.'filter'})) { $self->{filter} = $request_args->{$self->{prefix}.'filter'}; }
    if(defined($request_args->{$self->{prefix}.'columns'})) {
        if (ref $request_args->{$self->{prefix}.'columns'}) {
            $self->{columns} = $request_args->{$self->{prefix}.'columns'};
        }
        else {
            $self->{columns} = [ split(',', $request_args->{$self->{prefix}.'columns'}) ];
        }
    }
    if(defined($request_args->{$self->{prefix}.'show_all'})) { $self->{no_limit} = !!$request_args->{$self->{prefix}.'show_all'}; }
    if(defined($request_args->{$self->{prefix}.'show_remaining_columns'})) { $self->{show_remaining_columns} = 1; }
}

sub sql
{
    my $self = shift;
    my %defaults = (no_limit => 0);
    my %params = (%defaults, @_);

    my $data = $self->{saved_data_itr} ? $self->{saved_data_itr} : $self->data_itr(%params);
    my ($sql, @exec_args) = $data->sql;

    return ($sql, @exec_args);
}

sub data_itr
{
    my $self = shift;
    my %args = @_;

    if ($self->{resultset}) { # for use with DBIx::Class
        return new Tablesearch::Data::DBIC(tablesearch => $self, data => $self->{resultset}, %args);
    } else {
        return new Tablesearch::Data::DBI(tablesearch => $self, %args);
    }
}

# Get the column names that are in the table. This performs the hidden, auth, and column (user) filtering.
sub column_names {
    my ($self, $data) = @_;

    return @{$self->{saved_column_names}} if ($self->{saved_column_names});

    $data ||= ($self->{saved_data_itr} ? $self->{saved_data_itr} : $self->data_itr);

    my @field_names = @{$data->column_names};

    if ($self->{require_field_auth}) {
        # Enforce field auth (if enabled)
        for (my $i = 0; $i < scalar(@field_names); $i++) {
            if (!defined($self->{field_params}->{$field_names[$i]}->{auth})
            || (defined($self->{field_params}->{$field_names[$i]}->{auth}) && !$self->{field_params}->{$field_names[$i]}->{auth}))
            {
                splice(@field_names, $i, 1); $i--;
            }
        }
    }

    if (!$self->{include_hidden}) {
        for (my $i = 0; $i < scalar(@field_names); $i++) {
            if (defined($self->{field_params}->{$field_names[$i]}->{hidden}) && $self->{field_params}->{$field_names[$i]}->{hidden} != 0) {
                splice(@field_names, $i, 1); $i--;
            }
        }
    }

    if ($self->{columns}) {
        if (ref($self->{columns}) eq 'ARRAY') {
            my $i = 0;
            my %columns = map { $_ => $i++ } @{$self->{columns}};
            $self->{columns} = \%columns;
        }
        if (!$self->{show_remaining_columns}) {
            # remove any columns which aren't asked for
            for (my $i = 0; $i < scalar(@field_names); $i++) {
                if (!defined($self->{columns}->{$field_names[$i]})) { splice(@field_names, $i, 1); $i--; }
            }
        }

        my $i = 0;
        my %given_order = map { $_ => $i++ } @field_names;

        @field_names = sort {
                my $def_a = defined($self->{columns}->{$a}); my $def_b = defined($self->{columns}->{$b});
                (($def_a && !$def_b) ? -1 : 0) ||
                (($def_b && !$def_a) ? 1 : 0) ||
                (($def_a && $def_b) ? ($self->{columns}->{$a} <=> $self->{columns}->{$b}) : 0) ||
                ($given_order{$a} <=> $given_order{$b})
            } @field_names;
    }

    $self->{saved_column_names} = \@field_names;

    return @field_names;
}

# Get unfiltered list of possible column names
# Ex: 'print Dumper($ts->raw_column_names);
sub raw_column_names {
    my $self = shift;

    my $data = $self->{saved_data_itr} ? $self->{saved_data_itr} : $self->data_itr;

    return $data->column_names;
}

sub do_header
{
    my $self = shift;
    my $output = $self->{output};
    $output->start_header(self=>$self);

    my @field_names = $self->column_names;
    my $field_params = $self->{field_params};

    # Output the header
    for(my $i = 0; $i < scalar(@field_names); $i++) {
        my $field_name = $field_names[$i];
        my $field_param = $field_params->{$field_name};
        my $sort_name = $field_param->{sort_name} || $field_name;

        $field_name = $self->format_field_name($field_name);

        $output->header(self=>$self, name=>$field_name, sortname=>$sort_name, params=>$field_param);
    }

    $output->end_header(self=>$self);
}

sub format_field_name
{
    my ($self, $field_name) = @_;
    if (defined($self->{field_params}->{$field_name}->{name})) {
        return $self->{field_params}->{$field_name}->{name};
    } else {
        my $disp_format = $self->{field_params}->{$field_name}->{header_format} || $self->{header_format} || '';
        return $self->{format_escape_er}->($field_name, $disp_format);
    }
}

sub do_data
{
    my $self = shift;
    my $output = shift; #XXX format
    $output ||= $self->{output};
    die "Output object required as first argument or set as \$self->{output}, not " . ref $output unless (ref $output && (ref $output) =~ /Output/);

    my %args = @_;

    my ($query, $join, $rows, $pages, $sort_order);
    # allow passing in escaper_format to get data output for a different format (ex. dump but with html formatting)
    my $escaper_format = $args{'escape_format'} || lc($output->name);

    my $data = $self->{saved_data_itr} = $self->data_itr(no_limit => ($self->{no_limit} == 1 || $output->name eq 'Excel'));

    my $format_escape_er = sub {
        my ($text, $disp_format, $vars) = @_;

        if(ref($disp_format) eq 'CODE') {
            return $disp_format->($text, $disp_format, $vars, $self);
        } elsif($disp_format eq 'uc') {
            $text = uc($text);
        } elsif($disp_format eq 'ucfirst') {
            $text = ucfirst($text);
        } elsif($disp_format eq 'lc') {
            $text = lc($text);
        } elsif($disp_format eq 'ucfirst_all') {
            $text = join(" ",map(ucfirst,split("_",$text)));
        } elsif($disp_format eq 'currency') {
            return $self->currency_formatter($text, $escaper_format);
        }

        # If they provide their own sub, then we expect them to escape
        # (so they can throw in html), otherwise we do...
        if (($escaper_format eq 'html')) {
            return HTML::Entities::encode_entities($text);
        } else {
            return $text;
        }
    };
    $self->{format_escape_er} = $format_escape_er;

    if ($data->execute) {
        my @field_names = $self->column_names;
        my $field_params = $self->{field_params};

        $self->do_header;

        # Output the data
        my $incr = 0;
        while (my $rowref = $data->next) {
            my %row = %$rowref;
            $output->start_row(self=>$self, row=>\%row);

            if ($self->{tmp}->{skiprow}) {
                delete $self->{tmp}->{skiprow};
                next;
            }

            my $field_i = 0;
            foreach my $i (@field_names) {
                my $field_param = $field_params->{$i};
                my $data_format = (defined($self->{data_format}) ? $self->{data_format} : '');
                if (defined($field_param->{data_format})) {
                    $data_format = $field_param->{data_format};
                }

                my $value = $format_escape_er->((defined($row{$i}) ? $row{$i} : $field_param->{'empty_value'}), $data_format, \%row);

                my $m = HTML::Mason::Request->instance or die "No mason!";
                my $_u = sub { return $m->interp->apply_escapes($_[0], 'u') };

                # XXX duplicated between here and the .comp
                my $eval = sub {
                    my $in = shift;
                    if (defined($in)) {
                        my @matches = $in =~ m/(\$row\{\w+\}|\$incr)/g;
                        foreach my $match (@matches) {
                            if (defined(my $evaled = eval($match))) {
                                $evaled = $_u->($evaled);
                                $in =~ s/\Q$match\E/$evaled/g;
                            }
                            else {
                                $in =~ s/\Q$match\E//g;
                            }
                        }
#                        $in =~ s/(\$row\{\w+\}|\$incr)/$1/gee;
                    }
                    return $in;
                };

                # XXX this needs to be refactored into some kind of data formatting part of TS
                # (separate from the output formatting currently located in tablesearch.comp)
                if ($escaper_format eq 'html') {
                    my $url = $eval->($field_param->{'url'});

                    if ($url && defined $value && ($row{$i} || !defined($field_param->{'nourl_on_empty'}) || $field_param->{'nourl_on_empty'} == 0)) {
                        my $url_string = "<a href=\"$url\">" . $value . "</a>";
                        foreach my $match (@{$field_param->{'nourl'}}) {
                            $url_string = $value if $row{$i} =~ /$match/;
                        }
                        $value = $url_string;
                    }
                }

                $output->row_data(
                    self=>$self,
                    field_param=>$field_param,
                    data_format=>$data_format,
                    value=>$value,
                    row=>\%row,
                    i=>$i,
                    incr=>$incr,
                    type=>$query->{TYPE}->[$field_i]
                );

                $field_i++;
            }
            $output->end_row(self=>$self, row=>\%row);
            $incr++;
        }

        $self->{tmp}->{data} = $data;

        # TODO Should probably be in Output::HTML
        if (defined($self->{postdata})) {
            die "postdata must be a sub" unless (ref($self->{postdata}) eq 'CODE');
            $self->{tmp}->{html} .= $self->{postdata}->($self);
        }

        return 1;
    }

    return 0;
}

sub display
{
    my $self = shift;
    my $m = HTML::Mason::Request->instance;
    die 'No mason' if (!$m);

    if ($m->request_args->{$self->{prefix} . 'excel'}) {
        $self->excel;
        return;
    }

    $self->{output} = new Tablesearch::Output::HTML($self);

    $self->{output}->begin;
    if ($self->do_data($self->{output})) {
        $self->{output}->end(data => $self->{tmp}->{data}, html => $self->{tmp}->{html});
    }
}

sub excel
{
    my $self = shift;
    my $filename = shift;
    my $m = HTML::Mason::Request->instance;
    die 'No mason' if (!$m);

    if ($filename) {
        $self->{excel_filename} = $filename;
    }

    $self->{output} = new Tablesearch::Output::Excel;

    $self->{output}->begin(self => $self);

    if ($self->do_data($self->{output})) {
        $self->{output}->end(self => $self, data => $self->{tmp}->{data});
    }
}

sub dump
{
    my $self = shift;
    my $out = shift;

    if (ref($out) ne 'HASH') { $out = {}; }

    %$out = ( 'header' => [], 'data' => [] );

    $self->{output} = new Tablesearch::Output::Array;

    $self->{tmp}->{out} = $out;
    $self->do_data($self->{output}, @_);
    return $self->{tmp}->{out};
}

sub currency_formatter
{
    my $self = shift;
    my $value = shift;
    return '' unless (defined $value);
    my $output_format = shift || 'html';
    my $precision = shift || 2;
    my $negative = $value < 0;
    $value =~ s/^-//;
    $value = sprintf("\$%0.${precision}f", $value);
    if ($negative) {
        if ($output_format eq 'html') {
            return "<font color=\"red\">($value)</font>";
        }
        else {
            return "($value)";
        }
    }
    else {
        return $value;
    }
}

1;

