package Tablesearch::Output::Excel;

use strict;
use warnings;

sub new {
    my($class) = shift;

    bless {
    }, $class;
}


sub name {
	return 'Excel';
}

sub start_header {
    my $self = shift;
    my %args = @_;

    my $ts = $args{self};

    $ts->{tmp}->{col} = 0;
}

sub header {
    my $self = shift;
    my %args = @_;

    my $ts = $args{self};
    my $name = $args{name};
    my $sortname = $args{sortname};

    my $worksheet = $ts->{tmp}->{worksheet};

    $ts->{tmp}->{maxlen}->{$ts->{tmp}->{col}} = length($name);
    $worksheet->write(1, $ts->{tmp}->{col}++, $name);
}

sub end_header {
    my $self = shift;
    my %args = @_;

    my $ts = $args{self};

    $ts->{tmp}->{row} = 2;
}

sub start_row {
    my $self = shift;
    my %args = @_;

    my $ts = $args{self};

    $ts->{tmp}->{col} = 0;
}

sub row_data {
    my $self = shift;
    my %args = @_;

    my $ts = $args{self};
    my $field_param = $args{field_param};
    my $data_format = $args{data_format};
    my $value = $args{value};
    my %row = %{$args{row}};
    my $i = $args{i};
    my $type = $args{type} || '';

    my $worksheet = $ts->{tmp}->{worksheet};

    my $col = $ts->{tmp}->{col};
    if (!defined($ts->{tmp}->{maxlen}->{$col})) { $ts->{tmp}->{maxlen}->{$col} = 0; }
    if ($value && length($value) > $ts->{tmp}->{maxlen}->{$col}) { $ts->{tmp}->{maxlen}->{$col} = length($value); }

    if ($ts->{excel_handle_dates} && ($type eq DBI::SQL_TYPE_TIMESTAMP)) {
        # this requires that the db output the time date value in a sensible format
        # (mysql does, oracle must be told to not use its shitty default format--if you
        # use the connect from the db password file it will fix it for you)
        $value =~ s/ /T/;
        $worksheet->write_date_time($ts->{tmp}->{row}, $ts->{tmp}->{col}++, $value, $ts->{tmp}->{date_format});
    } else {
        $worksheet->write($ts->{tmp}->{row}, $ts->{tmp}->{col}++, $value);
    }
}

sub end_row {
    my $self = shift;
    my %args = @_;

    my $ts = $args{self};

    $ts->{tmp}->{row}++;
}

sub begin {
    my $self = shift;
    my %args = @_;

    my $ts = $args{self};

    use Spreadsheet::WriteExcel;
    use File::Temp qw/ tempfile tempdir /;

    my ($fh, $filename) = tempfile("tsearchexportXXXXXXXX", SUFFIX => '.xls', DIR => '/var/tmp' );

    my $workbook = Spreadsheet::WriteExcel->new($fh);
    my $worksheet = $workbook->add_worksheet();
    $worksheet->keep_leading_zeros;
    $ts->{tmp}->{workbook} = $workbook;
    $ts->{tmp}->{worksheet} = $worksheet;
    $ts->{tmp}->{filename} = $filename;
    $ts->{tmp}->{fh} = $fh;
    $ts->{tmp}->{date_format} = $workbook->add_format(num_format => 'mm/dd/yy');
}

sub end {
    my $self = shift;
    my %args = @_;

    my $ts = $args{self};

    # XXX remove
    my $m = HTML::Mason::Request->instance;
    my $r = $m->apache_req;

    my $workbook = $ts->{tmp}->{workbook};
    my $worksheet = $ts->{tmp}->{worksheet};

    sub get_time()
    {
        # about.com
        my @months = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
        my @weekDays = qw(Sun Mon Tue Wed Thu Fri Sat Sun);
        my ($second, $minute, $hour, $dayOfMonth, $month, $yearOffset, $dayOfWeek, $dayOfYear, $daylightSavings) = localtime();
        my $year = 1900 + $yearOffset;
        return "$hour:$minute:$second, $weekDays[$dayOfWeek] $months[$month] $dayOfMonth, $year";
    }

    # Adjust width
    my $factor = 0.95;
    my $col = 0;
    while (defined($ts->{tmp}->{maxlen}->{$col})) {
        $worksheet->set_column($col, $col, $ts->{tmp}->{maxlen}->{$col} * $factor);
        $col++;
    }

    $worksheet->write(0, 0, 'Export: ' . get_time());

    # Pretty header scrolling love (keeps it on the screen)
    $worksheet->freeze_panes(2, 0);

    # Pretty header printing love (keeps it on the page)
    $worksheet->repeat_rows(1, 2);

    $workbook->close();
    close($ts->{tmp}->{fh});

    # send file to client
    $r->content_type('application/ms-excel');
    $r->headers_out->unset('Content-Length');
    $r->headers_out->set('Content-Disposition' => 'file; filename="' . $ts->{excel_filename} . '.xls"');
    $r->headers_out->set('Content-Length' => -s $ts->{tmp}->{filename} );
    $m->clear_buffer();
    $m->autoflush(1);
    $r->sendfile($ts->{tmp}->{filename});
    $m->autoflush(0);

    $m->abort(Apache2::Const::OK);
}


1;
