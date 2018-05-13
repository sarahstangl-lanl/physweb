package ShopDb::GenerateInvoice;

use strict;
use warnings;

use File::Temp qw/tempfile/;
use POSIX qw/strftime/;
use File::Basename;

sub new {
    my $self = shift;

    # Hack to determine template path
    my $lib_dir = dirname($INC{'ShopDb/Schema.pm'});

    # Defaults
    my %defaults = (
        job_item => undef,
        packed_by => '',
        date => strftime('%m/%d/%Y', localtime),
        form_type => undef, # SHIPPING or INVOICE
        customer_address => '',
        customer_po => '',
        form_number => '',
        shipped_via => '',
        shipping_reference => '',
        form_lines => '',
        template_filename => "$lib_dir/InvoiceTemplate.tex",
        pdflatex_args => '-interaction batchmode -output-directory /tmp',
    );

    my %args = @_;

    # Check against unknown parameters
    while (my ($key, $value) = each(%args)) {
        die "Unknown parameter $key" unless (exists $defaults{$key});
    }

    # Validate parameters
    die "job_item is required and must be a Jobs object"
        unless ($args{job_item} && ref $args{job_item} eq 'ShopDb::Schema::Result::Jobs');
    for (qw/form_type customer_address form_lines/) {
        die "$_ is required" unless (defined $args{$_});
    }
    die "form_lines must be an arrayref" unless (ref $args{form_lines} eq 'ARRAY');
    die "Invalid type $args{form_type}" unless ($args{form_type} =~ /^(SHIPPING|INVOICE)$/);

    # Fill in some values from job_item
    $args{ship_address} = defined $args{job_item}->ship_address_id ? $args{job_item}->ship_address->to_string : '';
    $args{bill_address} = defined $args{job_item}->bill_address_id ? $args{job_item}->bill_address->to_string : '';
    $args{customer_name} = defined $args{job_item}->customer_id ? $args{job_item}->customer->directory->display_name : '';
    $args{pi_name} = defined $args{job_item}->pi_id ? $args{job_item}->pi->directory->display_name : '';

    bless({ %defaults, %args }, $self);
}

sub sanitize {
    my $self = shift;
    my $parameter = shift;
    if (ref $parameter eq 'ARRAY') {
        for (@$parameter) {
            $_ = $self->sanitize($_);
        }
    }
    else {
        # Escape ampersand and dollar sign
        $parameter =~ s/(&|\$)/\\$1/g;
        # Replace newline with \\
        $parameter =~ s/\r?\n/\\\\/g;
    }
    return $parameter;
}

sub generate {
    my $self = shift;
    my ($fh, $filename) = tempfile();

    # Sanitize variables
    for (qw/ship_address bill_address customer_address form_lines/) {
        $self->{$_} = $self->sanitize($self->{$_});
    }

    # Generate form lines
    $self->{manifest} = join("\n", map {
        # Split columns by | and join by &
        join('&', split(/\|/, $_, -1)) . "\\\\[3pt]\n";
    } @{$self->{form_lines}});

    # Add variable definitions to tex file
    print {$fh} qq[
\\newcommand{\\JOBNUMBER}{] . $self->{job_item}->id . qq[}
\\newcommand{\\JOBNAME}{] . $self->{job_item}->project_name . qq[}
\\newcommand{\\CUSTNAME}{$self->{customer_name}}
\\newcommand{\\PINAME}{$self->{pi_name}}
\\newcommand{\\PACKEDBY}{$self->{packed_by}}
\\newcommand{\\DATE}{$self->{date}}
\\newcommand{\\TYPE}{$self->{form_type}}
\\newcommand{\\BILLADDR}{$self->{bill_address}}
\\newcommand{\\SHIPADDR}{$self->{ship_address}}
\\newcommand{\\REMOTEADDR}{$self->{customer_address}}
\\newcommand{\\FORMNUMBER}{$self->{form_number}}
\\newcommand{\\CUSTOMERPO}{$self->{customer_po}}
\\newcommand{\\SHIPPEDVIA}{$self->{shipped_via}}
\\newcommand{\\SHIPPINGREF}{$self->{shipping_reference}}
\\newcommand{\\MANIFEST}{$self->{manifest}}
];

    # Append template to tex file
    open(my $template_fh, "<$self->{template_filename}") || die "Failed to open template $self->{template_filename}: $!";
    while(<$template_fh>) {
        print {$fh} $_;
    }
    close($template_fh);

    # Generate PDF
    warn "Generating invoice from $filename...\n";
#    my $filecontent = `cat $filename`;
#    my @lines = split /\n/, $filecontent;
#    my $i = 1;
#    warn join "\n", map { sprintf "%5d: %s", $i++, $_ } @lines;
    `/usr/local/bin/pdflatex $self->{pdflatex_args} $filename`;
    unless (-f "${filename}.pdf") {
        my $log = `cat ${filename}.log`;
        warn $log;
    }
    warn "Finished...\n";
    close($fh);
    return "${filename}.pdf";
}

1;
