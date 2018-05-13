package ShopDb::Form::EstimateChargeLine;

use HTML::FormHandler::Moose;
extends 'ShopDb::Form::RowEditor';

has 'estimate_item' => ( is => 'ro', required => 1 );

sub update_fields {
    my $self = shift;
#    $self->field('job_estimate_id')->noupdate(0);
}

sub validate {
    my $self = shift;
}

has_field 'category' => (
    required => 1,
    required_message => 'You must specify a category',
);

has_field 'category_value' => (
    type => '+EditableDropdown',
    required => 1,
    required_message => 'You must specify a category value',
);

has_field 'job_estimate_id' => (
    type => 'Hidden',
#    auth => [ ], # Only foreman
);

has_field 'description' => (
    type => 'Text',
    required => 1,
    required_message => "Description is required",
);

has_field 'extended_cost' => (
    type => '+Currency',
    auth => 0,
);

no HTML::FormHandler::Moose;
1;
