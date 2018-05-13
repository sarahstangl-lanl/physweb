package ShopDb::Field::DateRangeAttributes;

use HTML::FormHandler::Moose;

has 'wrapper_start' => ( isa => 'Bool', is => 'rw', default => 1 );
has 'wrapper_end' => ( isa => 'Bool', is => 'rw', default => 1 );
has 'align' => ( isa => 'Str', is => 'rw' );
has 'colspan' => ( isa => 'Int', is => 'rw' );
has 'hide' => ( isa => 'Bool', is => 'rw', default => 0 );
has 'empty_cell_before' => ( isa => 'Bool', is => 'rw', default => 0 );

no HTML::FormHandler::Moose;
1;
