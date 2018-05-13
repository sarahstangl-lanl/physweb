package ShopDb::Schema::ResultSet::Customers;

use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

sub with_directory_info {
    my ( $self ) = @_;

    return $self->search(
        {},
        {
            '+select' => [
                            \'CONCAT_WS(", ", directory.last_name, directory.first_name) AS customer_display_name',
                            'directory.email',
                            'directory.work_phone',
                            'directory.cell_phone',
                         ],
            '+as'     => [ 'customer_display_name', 'email', 'work_phone', 'cell_phone' ],
            join      => 'directory',
        }
    );
}

sub with_type_info {
    my $self = shift;
    return $self->search(
        {},
        {
            '+select'   => [ 'customer_type.label' ],
            '+as'       => [ 'customer_type' ],
            join        => [ 'customer_type' ],
        }
    );
}

sub with_address_info {
    my $self = shift;
    return $self->search(
        {},
        {
            '+select'   => [ qw/bill_address.lines ship_address.lines/ ],
            '+as'       => [ qw/billing_address shipping_address/ ],
            join        => [ qw/bill_address ship_address/ ],
        }
    );
}

1;
