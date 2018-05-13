package ShopDb::Form::JobComment;

use HTML::FormHandler::Moose;
extends 'ShopDb::Form::RowEditor';

has '+item_class' => ( default => 'JobComments' );

sub BUILD {
    my $self = shift;

    # Prefix field ids with 'comments_'
    for ($self->fields) {
        $_->id('comments_' . $_->id);
    }
}

sub update_fields {
    my $self = shift;

    # Set job_id, creator and created_date to active
    for (qw/job_id creator created_date/) {
        $self->field($_)->noupdate(0);
    }
}

sub validate {
    my $self = shift;

    # Set created_date to today
    $self->field('created_date')->value($self->today);

    # Set job_id to job_item job_id
    $self->field('job_id')->value($self->job_item->job_id);

    # Set creator to current user
    $self->field('creator')->value($self->_uid);
}

has_field 'job_id' => (
    type => 'Hidden',
    auth => 0,
);

has_field 'comment' => (
    type => 'Text',
    required => 1,
    required_message => 'Comment field is required.',
    auth => 1,
);

has_field 'creator' => (
    type => 'Text',
    auth => 0,
);

has_field 'created_date' => (
    type => '+Date',
    auth => 0,
);

sub default_created_date {
    my ($field, $item) = @_;
    return $field->form->today;
}

has_field 'include_on_invoice' => (
    type => 'Checkbox',
    style => 'margin: 1px 0 0 7px;',
);

has_field 'customer_visible' => (
    type => 'Checkbox',
    style => 'margin: 1px 0 0 7px;',
);

no HTML::FormHandler::Moose;
1;
