package UMPhysics::Field::CompletePeople;
use HTML::FormHandler::Moose;
extends 'HTML::FormHandler::Field::Text';

has '+widget' => ( default => 'CompletePeople' );
has 'include_shop_customers' => ( is => 'ro', default => 0 );

__PACKAGE__->meta->make_immutable;
use namespace::autoclean;
1;
