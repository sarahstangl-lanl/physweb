package ShopDb::Form::MaterialLine;

use HTML::FormHandler::Moose;
use List::MoreUtils qw/uniq/;
extends 'ShopDb::Form::ChargeLine';

has '+item_class' => ( default => 'MaterialLines' );
has '+id_prefix' => ( default => 'ml_' );

sub validate {
    my $self = shift;
    $self->field('unit_cost')->add_error("Unit cost is required if finalizing")
        if ($self->field('finalized')->value && ! defined $self->field('unit_cost')->value);
    $self->next::method;
}

has_field 'quantity' => (
    required => 1,
    required_message => 'You must specify a quantity',
    apply => [ { check => qr/^[-+]?[0-9]*\.?[0-9]+$/, message => 'Enter a valid quantity' } ]
);

has_field 'unit' => (
    type => '+EditableDropdown',
    required => 1,
    required_message => 'You must specify a unit',
);

sub options_unit {
    my ($self, $field) = @_;
    my @units = $self->schema->resultset('MaterialLines')->search({ }, { columns => [ 'unit' ], distinct => 1 })->get_column('unit')->all;
    my @default_units = ('box', 'ea', 'ft', 'in', 'min', 'sq in', 'lb', 'tr oz');
    return [ map { { value => $_, label => $_ } } sort &uniq (@default_units, @units) ];
}

has_field 'unit_cost' => (
    type => '+Currency',
    precision => 3,
);

no HTML::FormHandler::Moose;
1;

