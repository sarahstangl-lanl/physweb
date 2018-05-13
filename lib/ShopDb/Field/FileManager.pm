package ShopDb::Field::FileManager;
use HTML::FormHandler::Moose;
extends 'HTML::FormHandler::Field';

has '+widget' => ( default => 'FileManager' );

__PACKAGE__->meta->make_immutable;
use namespace::autoclean;
1;

