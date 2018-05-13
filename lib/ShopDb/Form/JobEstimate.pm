package ShopDb::Form::JobEstimate;

use HTML::FormHandler::Moose;
extends 'ShopDb::Form::Base';

has '+item_class' => ( default => 'JobEstimates' );
has '+widget_form' => ( default => 'Simple' );
#has '+widget_wrapper' => ( default => 'Table' );

has '+auth' => ( default => sub { sub {
    my ($auth_args, $self) = @_;
    my $creator_uid = $self->field('creator')->value;
    return ($auth_args->{foreman} || ($creator_uid && $auth_args->{uid} eq $creator_uid));
} });

has_field 'creator' => (
    auth => 0,
);

has_field 'labor_rate' => (
    type => '+Currency',
    label => 'Labor Rate ($/hr)',
    size => 5,
#    auth => 1,
);

has_field 'edm_labor_rate' => (
    type => '+Currency',
    label => 'EDM Labor Rate ($/hr)',
    size => 5,
#    auth => 1,
);

has_field 'update_submit' => (
    type => 'Submit',
    label => 'Update',
);

sub render {
    my $self = shift;
    my $output = '<form action="estimate.html?job_id=' . $self->item->job_id . '" method="POST"><table style="padding-top: 5px;" cellpadding="3" cellspacing="0">';
    for my $field (qw/labor_rate edm_labor_rate update_submit/) {
        $output .= $self->field($field)->render;
    }
    $output .= '</table></form>';
    return $output;
}

no HTML::FormHandler::Moose;
1;
