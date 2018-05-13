package ShopDb::Field::DateRange;

use HTML::FormHandler::Moose;
extends 'HTML::FormHandler::Field::Compound';

has_field 'type' => (
    type => '+DateSelect',
    label => '',
    options => [
        { value => 'equals', label => 'Exactly' },
        { value => 'before', label => 'Before' },
        { value => 'after', label => 'After' },
        { value => 'between', label => 'Between' },
    ],
    wrapper_end => 0,
    align => 'right',
);

has_field 'start' => (
    type => '+Date',
    label => '',
    wrapper_start => 0,
);

has_field 'end' => (
    type => '+Date',
    label => '',
    hide => 1,
    empty_cell_before => 1,
);

__PACKAGE__->meta->make_immutable;
use namespace::autoclean;
1;
