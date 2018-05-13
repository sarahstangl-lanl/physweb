package ShopDb::Field::DateSelect;

use HTML::FormHandler::Moose;
extends 'HTML::FormHandler::Field::Select', 'ShopDb::Field::DateRangeAttributes';

has '+widget' => ( default => 'DateSelect' );

sub build_element_attr {
    my $self = shift;
    (my $base_id = $self->id) =~ s/\..*$//;
    return {
        onchange => 'checkType' . ucfirst($base_id) . '(this.value)',
    };
}

__PACKAGE__->meta->make_immutable;
use namespace::autoclean;
1;
