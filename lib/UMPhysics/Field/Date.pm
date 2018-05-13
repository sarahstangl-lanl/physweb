package UMPhysics::Field::Date;

use HTML::FormHandler::Moose;
extends 'HTML::FormHandler::Field::Date', 'ShopDb::Field::DateRangeAttributes';

has '+widget' => ( default => 'Date' );

# HTML::FormHandler::Field::Date validate replaces original value with DateTime object
sub validate {
    my $self = shift;

    my $format = $self->get_strf_format;
    my $strp = DateTime::Format::Strptime->new( pattern => $format );

    unless ($strp->parse_datetime( $self->value )){
        $self->add_error( "Please enter a date in YYYY-MM-DD format." );
        return;
    }
}

__PACKAGE__->meta->make_immutable;
use namespace::autoclean;
1;
