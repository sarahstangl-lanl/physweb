package ShopDb::Field::CompleteCustomer;
use HTML::FormHandler::Moose;
extends 'HTML::FormHandler::Field::Text';

has '+widget' => ( default => 'CompleteCustomer' );
has '+fif_from_value' => ( default => 1 );
has '+deflate_method' => ( default => sub { \&deflate_customer } );
has 'prefix' => ( is => 'rw', default => '' );
has 'include_shop_customers' => ( is => 'ro', default => 1 );
has 'no_add_button' => ( isa => 'Bool', is => 'ro', default => 0 );

sub deflate_customer {
    my ($self, $value) = @_;

    if (ref $value eq 'ShopDb::Schema::Result::Customers') {
        warn "value is Customer object";
        return $value;
    }
    if ($self->form->item) {
        my $accessor = $self->accessor;
        warn "Returning item value for field $accessor";
        return $self->form->item->$accessor;
    }
    if ($self->default) {
        warn "Returning field default";
        return $self->default;
    }
    if ($value) {
        my $customer = $self->form->schema->resultset('Customers')->find($value);
        warn "Returning looked-up customer object " . $customer;
        return $customer;
    }
    return $value;
}

sub validate {
    my $field = shift;
    warn "ShopDb::Field::CompleteCustomer::validate called with value " . $field->value . " for field " . $field->name;
    if ($field->readonly) {
        warn "ShopDb::Field::CompleteCustomer::validate: Setting field " . $field->name . " to default";
        $field->value($field->get_default_value);
        return;
    }
    if ($field->noupdate) {
        warn "ShopDb::Field::CompleteCustomer::validate: Field set to noupdate, bailing";
        return;
    }
    if (ref($field->input) ne 'ShopDb::Schema::Result::Customers') {
        # If customer input is all digits, assume directory uid
        if ($field->input =~ /^\d+$/) {
            warn "ShopDb::Field::CompleteCustomer::validate: Trying to find customer with directory_uid " . $field->input . " for field " . $field->name;
            if (my $customer = $field->form->schema->resultset('Customers')->find({ directory_uid => $field->input })) {
                $field->value($customer);
                return;
            }
            elsif (my $directory = $field->form->schema->resultset('DirectoryEntry')->find({ uid => $field->input })) {
                $field->value($field->form->schema->resultset('Customers')->new({ directory => $directory }));
                return;
            }
        }
        # Else assume it is x500 and new customer needs to be created
        else {
            warn "ShopDb::Field::CompleteCustomer::validate: Trying to find x500 " . $field->input . " in UMN LDAP for field " . $field->name;
            # Make sure a directory entry with new x500 doesn't already exist
            my $directory = $field->form->schema->resultset('DirectoryEntry')->find({ x500 => $field->input });
            if ($directory) {
                warn "Found an existing directory entry";
                $field->value($directory->find_or_new_related('customer', { }));
                return;
            }
            use Net::LDAP;
            my $ldap = Net::LDAP->new( 'ldap.umn.edu', timeout => 5 ) or return $field->add_error("Failed to fetch information from UMN LDAP server. Please try again.");
            $ldap->bind or return $field->add_error("Failed to fetch information from UMN LDAP server. Please try again.");
            my $mesg = $ldap->search( base => "o=University of Minnesota,c=US", filter => '(uid=' . $field->input . ')', sizelimit => 1 );
            $ldap->unbind;
            return $field->add_error("Invalid customer name") unless ($mesg->count);
            my $ldap_entry = $mesg->entry(0);
            my $directory_entry = $field->form->schema->resultset('DirectoryEntry')->new({
                    last_name => $ldap_entry->get_value('sn') || '',
                    first_name => $ldap_entry->get_value('givenName') || '',
                    work_phone => $ldap_entry->get_value('telephoneNumber') || '',
                    email => $ldap_entry->get_value('umndisplaymail') || $ldap_entry->get_value('mail') || '',
                    x500 => $ldap_entry->get_value('uid'),
                    create_date => \'NOW()',
                    modified_date => \'NOW()',
            });
            $field->value($directory_entry->new_related('customer', { }));
            return;
        }

        $field->_clear_input;
        $field->_clear_value;
        return $field->add_error("Invalid customer name");
    }
}

__PACKAGE__->meta->make_immutable;
use namespace::autoclean;
1;
