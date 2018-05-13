package ShopDb::Form::LaborLine;

use HTML::FormHandler::Moose;
use Math::Round qw/nearest_ceil/;
extends 'ShopDb::Form::ChargeLine';

has '+item_class' => ( default => 'LaborLines' );
has '+id_prefix' => ( default => 'll_' );

has_field 'charge_hours' => (
    required => 1,
    required_message => 'You must specify the charge hours',
    fif_from_value => 1,
    apply => [
        { transform => sub { nearest_ceil(0.25, $_[0]) } },
    ],
);

has_field 'labor_rate' => (
    auth => 0,
);

no HTML::FormHandler::Moose;
1;
