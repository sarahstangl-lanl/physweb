package ShopDb::TablesearchMethods;

use warnings;
use strict;

use Sub::Name qw/subname/;
use MasonHelper;

sub new {
    my $class = shift;
    my %args = @_ || ();
    my %defaults = (
        'job_id' => {
            name => 'Job ID',
            data_format => sub {
                my ($value, $self, $row, $ts) = @_;
                return $value if ( $ts->{output}->name eq 'Excel');
                if (defined($row->{parent_job_id})) {
                    $value = $row->{'parent_job_id'};
                }
                my $url = '<a href="job.html?job_id=' . $row->{'job_id'} . '">' . $value . '</a>';
                return $url;
            },
            sort_name => 'job_id_sort_val',
        },
        project_name => {
            name => 'Project Name',
            data_format => sub {
                my ($value, $self, $row, $ts) = @_;
                unless (exists($row->{job_id})) {
                    die "project_name requires 'job_id' field to exist";
                }
                return $value if ( $ts->{output}->name eq 'Excel');
                my $url = '';
                if ($row->{parent_job_id} && $row->{parent_name}) {
                    $url .= '<a href="job.html?job_id=' . $row->{parent_job_id} . '">' . $row->{parent_name} . '</a>: ';
                }
                $url .= '<a href="job.html?job_id=' . $row->{job_id} . '">' . $row->{project_name} . '</a>';
                return $url;
            },
        },
        customer_id => {
            name => 'Customer',
            data_format => sub {
                my ($value, $self, $row, $ts) = @_;
                unless (exists($row->{customer_display_name})) {
                    die "customer_id requires 'customer_display_name' field to exist";
                }
                return defined $value ?
                    ( $ts->{output}->name eq 'Excel' ?
                        $row->{customer_display_name} :
                        '<a href="customer.html?customer_id=' . $row->{customer_id} . '">' . $row->{customer_display_name} . '</a>'
                    ) : '';
            },
            sort_name => 'customer_display_name',
        },
        pi_id => {
            name => 'PI',
            data_format => sub {
                my ($value, $self, $row, $ts) = @_;
                unless (exists($row->{pi_display_name})) {
                    die "pi_id requires 'pi_display_name' field to exist";
                }
                return defined $value ?
                    ( $ts->{output}->name eq 'Excel' ?
                        $value :
                        '<a href="customer.html?customer_id=' . $row->{pi_id} . '">' . $row->{pi_display_name} . '</a>'
                    ) : '';
            },
        },
        machinist_id => {
            name => 'Machinist',
            data_format => sub {
                my ($value, $self, $row, $ts) = @_;
                unless (exists($row->{display_name})) {
                    die "machinist_id requires 'display_name' field to exist";
                }
                return defined $value ?
                    ( $ts->{output}->name eq 'Excel' ?
                        $row->{display_name} :
                        '<a href="machinist.html?machinist_id=' . $row->{machinist_id} . '">' . $row->{display_name} . '</a>'
                    ) : '';
            },
            sort_name => 'display_name',
        },
        address => {
            data_format => sub {
                my ($value, $self, $row, $ts) = @_;
                return defined $value ?
                    ( $ts->{output}->name eq 'Excel' ?
                        $value :
                        join('<br/>', split(/[\r\n]+/, $value))
                    ) : '';
            },
        },
        account => {
            name => 'EFS Account',
            data_format => sub {
                my ($value, $self, $row, $ts) = @_;
                unless (exists($row->{account_key})) {
                    die "account requires 'account_key' field to exist";
                }
                return defined $value ?
                    ( $ts->{output}->name eq 'Excel' ?
                        $value :
                        '<a href="account.html?account_key=' . _u($row->{account_key}) . '">' . _h($value) . '</a>'
                    ) : '';
            },
        },
        account_key => {
            name => 'EFS Chartstring',
            data_format => sub {
                my ($value, $self, $row, $ts) = @_;
                return defined $value ?
                    ( $ts->{output}->name eq 'Excel' ?
                        $value :
                        '<a href="account.html?account_key=' . _u($value) . '">' . _h($value) . '</a>'
                    ) : '';
            },
        },
        checkbox => {
            data_format => sub {
                my ($value, $self, $row, $ts) = @_;
                return $ts->{output}->name eq 'Excel' ?
                    ( $value  ?
                        'Checked' :
                        'Unchecked'
                    ) : '<input type="checkbox" disabled="disabled"' . ($value ? ' checked="checked"' : '') . '/>';
            },
        },
    );
    %args = (%defaults, %args);
    my $self = bless(\%args, $class);
    no strict 'refs';
    no warnings 'redefine';
    for my $key (keys (%args)) {
        my $method_name = join '::', __PACKAGE__, $key;
        *$method_name = subname $method_name, sub { return shift->{$key} };
    }
    return $self;
}

1;
