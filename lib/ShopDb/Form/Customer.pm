package ShopDb::Form::Customer;

use HTML::FormHandler::Moose;
extends 'ShopDb::Form::Base';

has '+item_class' => ( default => 'Customers' );
has 'customer_item' => ( is => 'ro' );
has '+widget_form' => ( default => 'Simple' );

my @directory_fields = qw/last_name first_name email work_phone cell_phone/;
my @customer_fields = qw/customer_id customer_type title company_name fax_number primary_ship_address primary_bill_address comments/;

sub BUILD {
    my $self = shift;
    if ($self->has_auth_edit_fields) {
        if ($self->item) {
            $self->field('customer_update')->readonly(0);
            $self->field('customer_update')->inactive(0);
        }
        else {
            $self->field('customer_add')->readonly(0);
            $self->field('customer_add')->inactive(0);
        }
    }
}

sub build_form_tags {
    {
        after_start => '<table>',
        before_end => '</table>',
        after => sub {
            my $self = shift;
            my $customer = $self->customer_item;
            if ($customer && !$customer->shopdb) {
                return '<h5>Note:</h5><p>Only certain fields can be modified for customers retrieved from the Physics Directory. Please contact directory@physics.umn.edu for corrections.</p>';
            }
            return '';
        },
        no_form_message_div => 1,
    }
}

has_field 'customer_id' => (
    type => 'Hidden',
    auth => 0,
);

has_field 'customer_type' => (
    auth => [ { item => [ 'new' ] }, { auth_args => [ 'foreman' ] } ],
    type => 'Select',
    label_column => 'label',
    sort_column => 'sort_order',
    required => 1,
);

has_field 'title' => (
    label => 'Title (Dr., Prof., etc.)',
    auth => [ { item => [ 'new' ] }, { auth_args => [ 'foreman' ] } ],
    style => 'width:300px',
    auth_over_foreman => 1,
);

has_field 'last_name' => (
    auth => [ { item => [ 'new' ] }, { item => [ 'shopdb' ], auth_args => [ 'foreman' ] } ],
    auth_over_foreman => 1,
    not_nullable => 1,
    style => 'width:300px',
    required => 1,
);

has_field 'first_name' => (
    auth => [ { item => [ 'new' ] }, { item => [ 'shopdb' ], auth_args => [ 'foreman' ] } ],
    auth_over_foreman => 1,
    not_nullable => 1,
    style => 'width:300px',
    required => 1,
);

has_field 'company_name' => (
    auth => [ { item => [ 'new' ] }, { auth_args => [ 'foreman' ] } ],
    auth_over_foreman => 1,
    style => 'width:300px',
);

has_field 'email' => (
    auth => [ { item => [ 'new' ] }, { item => [ 'shopdb' ], auth_args => [ 'foreman' ] } ],
    auth_over_foreman => 1,
    style => 'width:300px',
    not_nullable => 1,
);

has_field 'work_phone' => (
    auth => [ { item => [ 'new' ] }, { item => [ 'shopdb' ], auth_args => [ 'foreman' ] } ],
    auth_over_foreman => 1,
    style => 'width:300px',
    not_nullable => 1,
#    required => 1,
);

has_field 'cell_phone' => (
    auth => [ { item => [ 'new' ] }, { item => [ 'shopdb' ], auth_args => [ 'foreman' ] } ],
    auth_over_foreman => 1,
    style => 'width:300px',
    not_nullable => 1,
);

has_field 'fax_number' => (
    auth => [ { item => [ 'new' ] }, { auth_args => [ 'foreman' ] } ],
    auth_over_foreman => 1,
    style => 'width:300px',
);

has_field 'primary_ship_address' => (
    type => 'CompleteAddress',
    dropdown_ids => [ 'customer_id' ],
    ddParamName => 'customer_id',
    label => 'Primary shipping address',
    auth => [ { item => [ 'new' ] }, { auth_args => [ 'foreman' ] } ],
    auth_over_foreman => 1,
    style => 'width:300px;vertical-align:top;',
    nowrap => => 1,
);

has_field 'primary_bill_address' => (
    type => 'CompleteAddress',
    dropdown_ids => [ 'customer_id' ],
    ddParamName => 'customer_id',
    label => 'Primary billing address',
    auth => [ { item => [ 'new' ] }, { auth_args => [ 'foreman' ] } ],
    auth_over_foreman => 1,
    style => 'width:300px;vertical-align:top;',
    nowrap => => 1,
);

has_field 'comments' => (
    type => 'TextArea',
    rows => 5,
#    cols => 25,
    auth => [ { item => [ 'new' ] }, { auth_args => [ 'foreman' ] } ],
    auth_over_foreman => 1,
    style => 'width:300px',
);

has_field 'customer_add' => (
    type => 'Submit',
    value => 'Add Customer',
    inactive => 1,
    auth => 0,
);

has_field 'customer_update' => (
    type => 'Submit',
    value => 'Update Customer',
    inactive => 1,
    auth => 0,
);

# Item is passed in as customer_item on new instead of item so that init_object will be called
# $self->item is set to customer_item at the end of init_object
sub init_object {
    my $self = shift;
    return unless $self->customer_item;
    my $customer = $self->customer_item;
    my $directory = $customer->directory;
    my $values = ();
    # Fill in directory fields
    for (@directory_fields) {
        $values->{$_} = $directory->$_ if $directory->can($_);
    }
    # Fill in customer fields
    for (@customer_fields) {
        $values->{$_} = $customer->$_ if $customer->can($_);
    }
    $self->item($self->customer_item);
    return $values;
}

sub update_model {
    my $self = shift;
    my $item = $self->item;

    return unless ($self->has_auth_edit_fields);

    # Build directory args
    my %directory_args = ();
    for (@directory_fields) {
        $directory_args{$_} = $self->value->{$_} if ($self->field($_)->has_auth);
    }

    # Build customer args
    my %customer_args = ();
    for (@customer_fields) {
        $customer_args{$_} = $self->value->{$_} if ($self->field($_)->has_auth);
    }

    if (!$item) { # new customer
        $self->schema->txn_do(sub {
            my $directory = $self->schema->resultset('DirectoryEntry')->create({ %directory_args });
            warn "Created directory entry: " . $directory->uid;
            $self->item(DBIx::Class::ResultSet::RecursiveUpdate::Functions::recursive_update(
                resultset => $self->resultset,
                object => undef,
                updates => { %customer_args, directory_uid => $directory->uid },
                unknown_params_ok => 1,
            ));
        });
    }
    else { #existing customer
        $self->schema->txn_do(sub {
            $item = DBIx::Class::ResultSet::RecursiveUpdate::Functions::recursive_update(
                resultset => $self->resultset,
                object => $item,
                updates => \%customer_args,
                unknown_params_ok => 1,
            );
            $item->directory->update({ %directory_args });
        });
        $self->item($item) if ($item);
    }
}

no HTML::FormHandler::Moose;

1;
