package ShopDb::Form::EstimateMaterialLine;

use HTML::FormHandler::Moose;
use List::MoreUtils qw/uniq/;
extends 'ShopDb::Form::EstimateChargeLine';

has '+item_class' => ( default => 'EstimateMaterialLines' );

sub options_category_value {
    my ($self, $field) = @_;
    my $category = $self->field('category')->get_default_value;
    my @values = $self->schema->resultset('EstimateMaterialLines')->search({ category => $category }, { columns => [ 'category_value' ], distinct => 1 })->get_column('category_value')->all;
    my $default_values = {
        general => [ 'Purchased Item', 'Purchased Stock', 'Shop Stock', 'Tooling' ],
        consumables => [ 'Abr. Water Jet', 'EDM Drill', 'Tooling' ],
        misc => [ 'Shipping', 'Heat Treatment', 'Plating/Coating', 'External Work' ],
    };
    die "Invalid category default $category" unless (exists $default_values->{$category});
    my @default_values = @{$default_values->{$category}};
    my $options = [ map { { value => $_, label => $_ } } sort &uniq (@default_values, @values) ];
    return $options;
}

has_field 'quantity' => (
    required => 1,
    required_message => 'You must specify a quantity',
    apply => [ { check => qr/^[0-9]+$/, message => 'Enter a valid quantity' } ]
);

has_field 'unit' => (
    type => '+EditableDropdown',
    required => 1,
    required_message => 'You must specify a unit',
);

sub options_unit {
    my ($self, $field) = @_;
    my @units = $self->schema->resultset('EstimateMaterialLines')->search({ }, { columns => [ 'unit' ], distinct => 1 })->get_column('unit')->all;
    my @default_units = ('box', 'ea', 'ft', 'in', 'min', 'sq in', 'lb', 'tr oz');
    return [ map { { value => $_, label => $_ } } sort &uniq (@default_units, @units) ];
}

has_field 'unit_cost' => (
    type => '+Currency',
);

no HTML::FormHandler::Moose;
1;

