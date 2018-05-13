package ShopDb::Field::CompleteAccount;
use HTML::FormHandler::Moose;
extends 'HTML::FormHandler::Field::Text';

has '+widget' => ( default => 'CompleteAccount' );
has 'dropdown_ids' => ( isa => 'ArrayRef', is => 'rw', default => sub { [ 'customer_uid', 'pi_uid' ] } );
has 'no_dropdown_button' => ( isa => 'Bool', is => 'rw', default => 0 );
has 'no_add_button' => ( isa => 'Bool', is => 'ro', default => 0 );

sub validate {
    my ($field) = shift;
    return if $field->noupdate;

    my $schema = $field->form->schema;
    my $account_key = $field->input;
    if (my $account = $schema->resultset('Accounts')->find($account_key)) {
        return $field->add_error("This account has been marked 'Do not use'. Please choose another account.")
            if ($account->disabled);
    }
    else {
        return $field->add_error("Invalid Account name");
    }
}

__PACKAGE__->meta->make_immutable;
use namespace::autoclean;
1;
