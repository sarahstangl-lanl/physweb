package ShopDb::Form::ChargeLine;

use HTML::FormHandler::Moose;
extends 'ShopDb::Form::RowEditor';

sub update_fields {
    my $self = shift;
    $self->field('machinist')->noupdate(0);
    $self->field('job_id')->noupdate(0);
}

sub validate {
    my $self = shift;

    # Set machinist_id to current machinist if not foreman
    if (!$self->auth_args->{'foreman'}) {
        $self->field('machinist')->value($self->_machinist_id);
    }

    # Set job_id to passed in job_item->job_id if not foreman
    if (!$self->auth_args->{'foreman'}) {
        $self->field('job_id')->value($self->job_item->job_id);
    }

    # Don't allow charges to be active on cancelled jobs
    if ($self->job_item->status->label eq 'Cancelled') {
        if (!$self->item) {
            $self->add_form_error("Charge lines cannot be added to cancelled jobs");
        }
        elsif ($self->field('active')->value) {
            $self->add_form_error("Charge lines cannot be made active on cancelled jobs");
        }
    }

    $self->field('machinist')->add_error("Machinist is required") unless $self->field('machinist')->value;
}

has_field 'job_id' => (
    type => 'Select',
    auth => [ ], # Only foreman
);

sub options_job_id {
    my $self = shift;
    my @jobs = ( $self->job_item, $self->job_item->child_jobs->all );
    my @options;
    for (@jobs) {
        push(@options, {
            label => $_->project_name,
            value => $_->job_id,
            selected => $self->job_item->job_id eq $_->job_id,
        });
    }
    return @options;
}

has_field 'description' => (
    type => 'Text',
    required => 1,
    required_message => "Description is required",
);

has_field 'machinist' => (
    type => 'Select',
    label_column => 'shortname',
    empty_select => '',
    auth => [ ], # Only foreman
);

sub options_machinist {
    my $self = shift;
    # Put inactive machinists at the bottom of the list
    my @machinists = $self->schema->resultset('Machinists')->with_directory_info->search({ }, { order_by => [ { -desc => 'active' }, 'shortname' ] });
    my @options;
    for (@machinists) {
        push(@options, {
            label => $_->get_column('shortname'),
            value => $_->machinist_id,
            selected => $self->_machinist_id && $_->machinist_id eq $self->_machinist_id,
        });
    }
    return @options;
}

has_field 'charge_date' => (
    type => '+Date',
    required => 1,
    required_message => 'You must specify a charge date',
);

sub default_charge_date {
    my $self = shift;
    return $self->today;
}

has_field 'bill_date' => (
    type => '+Date',
);

has_field 'paid_date' => (
    type => '+Date',
);

has_field 'extended_cost' => (
    type => '+Currency',
    auth => 0,
);

has_field 'finalized' => (
    type => 'Checkbox',
    auth => [ { item => [ '!bill_date' ], auth_args => [ 'foreman' ] } ],
    auth_over_foreman => 1,
    style => 'margin: 1px 0 0 7px;',
);

has_field 'active' => (
    auth => [ ], # Only foreman
);

no HTML::FormHandler::Moose;
1;
