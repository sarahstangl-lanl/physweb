package ShopDb::Schema::ResultSet::LaborLines;

use strict;
use warnings;
use base 'ShopDb::Schema::ChargeLinesBase';

sub with_labor_rate {
    my ( $self ) = @_;

    return $self->search(
        {},
        {
            '+select' => [ 'machinist.labor_rate' ],
            '+as'     => [ 'labor_rate' ],
            join      => 'machinist',
        }
    );
}

sub with_extended_cost {
    my ( $self ) = @_;

    return $self->search(
        {},
        {
            '+select' => [ \'machinist.labor_rate * me.charge_hours' ],
            '+as'     => [ 'extended_cost' ],
            join      => 'machinist',
        }
    );
}

sub with_ts_fields {
    my ( $self ) = @_;

    return $self->with_labor_rate->with_extended_cost->with_directory_info;
}

1;
