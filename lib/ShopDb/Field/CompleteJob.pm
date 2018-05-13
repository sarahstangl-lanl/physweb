package ShopDb::Field::CompleteJob;
use HTML::FormHandler::Moose;
extends 'HTML::FormHandler::Field::Text';

has '+widget' => ( default => 'CompleteJob' );
has 'dropdown_ids' => ( isa => 'ArrayRef', is => 'rw', default => sub { [ ] } );
has 'no_dropdown_button' => ( isa => 'Bool', is => 'rw', default => 0 );
has 'ddParamName' => ( isa => 'Str', is => 'rw', default => 'parent_job_id' );
has 'recent' => ( isa => 'Bool', is => 'rw', default => 0 );

sub validate {
    my ($field) = shift;
    return if $field->noupdate;

    my $schema = $field->form->schema;
    my $job_id = $field->input;
    return $field->add_error("Invalid Job name") unless $schema->resultset('Jobs')->find($job_id);
}

__PACKAGE__->meta->make_immutable;
use namespace::autoclean;
1;
