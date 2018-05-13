package ShopDb::Form::FieldTrait;

use namespace::autoclean;
use HTML::FormHandler::Moose::Role;

has 'nowrap' => ( isa => 'Bool', is => 'rw', default => 0 );

has 'help_message' => ( isa => 'Str', is => 'rw', predicate => 'has_help_message' );

# Adds a block of javascript to the field output
# Script tags are added automatically
# Sub is called with field as an argument
has 'build_javascript' => ( is => 'rw', isa => 'CodeRef', predicate => 'has_build_javascript' );

sub build_read_auth {
    return [ { item => [ 'new' ] }, { item => [ '!new' ], auth_args => [ 'customer', 'pi', 'machinist_id' ] } ];
}

1;
