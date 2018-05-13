package ShopDb::Schema::ResultSet::MaterialLines;

use strict;
use warnings;
use base 'ShopDb::Schema::ChargeLinesBase';

sub with_extended_cost {
    my ( $self ) = @_;

    return $self->search(
        {},
        {
            '+select' => [ \'me.quantity * me.unit_cost' ],
            '+as'     => [ 'extended_cost' ],
        }
    );
}

sub with_ts_fields {
    my ( $self ) = @_;

    return $self->with_extended_cost->with_directory_info;
}

1;
