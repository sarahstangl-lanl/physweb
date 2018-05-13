package ShopDb::Field::CompleteAddress;

use HTML::FormHandler::Moose;
extends 'HTML::FormHandler::Field::TextArea';

has '+widget' => ( default => 'CompleteAddress' );
has 'no_dropdown_button' => ( isa => 'Bool', is => 'rw', default => 0 );
has 'no_add_button' => ( isa => 'Bool', is => 'ro', default => 0 );
has 'dropdown_ids' => ( isa => 'ArrayRef', is => 'rw', default => sub { [ ] } );
has 'ddParamName' => ( isa => 'Str', is => 'rw', default => 'customer_uid' );

sub validate {
    my ($field) = shift;
    return if $field->noupdate;

    my $schema = $field->form->schema;
    my $address_id = $field->input;
    return $field->add_error("Invalid Address") unless ($schema->resultset('Addresses')->find($address_id));
}

__PACKAGE__->meta->make_immutable;
use namespace::autoclean;
1;
