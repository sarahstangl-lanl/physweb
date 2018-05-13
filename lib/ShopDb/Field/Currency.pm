package ShopDb::Field::Currency;

use HTML::FormHandler::Moose;
extends 'HTML::FormHandler::Field::Text';

has '+deflate_method' => ( default => sub { \&deflate_currency } );
has 'precision' => ( isa => 'Int|Undef', is => 'rw', default => 2 );

apply(
    [
        {
            transform => sub {
                my $value = shift;
                $value =~ s/[\$\)]//g;
                $value =~ s/^\(/-/;
                return $value;
            }
        },
        {
            check => sub { $_[0] =~ /^-?[0-9]*\.?[0-9]+?$/ },
            message => 'Value must be currency'
        },
    ]
);

sub validate {
    my $field = shift;
    my $value = sprintf ('%.' . $field->precision . 'f', $field->value);
    return $field->add_error('Value cannot be converted to money') unless ($value);
    return 1;
}

sub deflate_currency {
    warn "Currency::deflate called with value " . (defined $_[1] ? $_[1] : 'undef');
    my ($self, $value) = @_;
    $value ||= $self->value;
    $value = defined $value ? $value : 0;
    my $negative = ($value < 0);
    $value = abs($value);
    $value = sprintf '' . ($negative ? '(' : '') . '$%0.' . $self->precision . 'f' . ($negative ? ')' : ''), $value;
    warn "Deflated value: $value";
    return $value;
}

__PACKAGE__->meta->make_immutable;
use namespace::autoclean;
1;
