package ShopDb::Form::PackingSlip;

use HTML::FormHandler::Moose;
use List::MoreUtils qw/uniq/;
extends 'ShopDb::Form::Base';

has '+item_class' => ( default => 'PackingSlips' );
has 'job_item' => ( is => 'ro', required => 1 );

sub BUILD {
    my $self = shift;
    $self->field('pi_uid')->value($self->job_item->pi_id ? $self->job_item->pi->directory_uid : '');
    $self->field('customer_uid')->value($self->job_item->customer_id ? $self->job_item->customer->directory_uid : '');
}

has_field 'job_id' => (
    widget => 'NoRender',
);
has_field 'creator_uid' => (
    type => 'Hidden',
);
has_field [ qw/pi_uid customer_uid/ ] => (
    type => 'Hidden',
    auth => 0,
);
has_field 'ship_via' => (
    type => 'EditableDropdown',
    required => 1,
);
sub options_ship_via {
    my ($self, $field) = @_;
    my @via = $self->schema->resultset('PackingSlips')->search({ }, { columns => [ 'ship_via' ], distinct => 1 })->get_column('ship_via')->all;
    my @default_via = ('COMPANY TRUCK', 'FED EX', 'DYNAMIC', 'SUPERIOR FREIGHT', 'UPS', 'US POST', 'WILL CALL', 'TRAFFIC MANAGEMENT', 'CAMPUS MAIL', 'DELIVERY', 'TRUCK');
    return [ map { { value => $_, label => $_ } } sort &uniq (@default_via, @via) ];
}
has_field 'ship_reference' => (

);
has_field 'ship_address' => (
    type => 'CompleteAddress',
    dropdown_ids => [ qw/customer_uid pi_uid/ ],
    cols => 20,
#    required => 1,
);
has_field 'ship_date' => (
    type => 'Date',
);
has_field 'slip_add' => (
    type => 'Submit',
    value => 'Create Packing Slip',
    inactive => 1,
);
has_field 'slip_update' => (
    type => 'Submit',
    value => 'Update Packing Slip',
    inactive => 1,
);

sub validate {
    my $self = shift;
    # Set job_id
    $self->field('job_id')->value($self->job_item->id);
    # Set creator uid
    if ($self->item->in_storage) {
        $self->field('creator_uid')->value($self->item->creator_uid);
    }
    else {
        $self->field('creator_uid')->value($self->_uid);
    }
}

no HTML::FormHandler::Moose;
1;
