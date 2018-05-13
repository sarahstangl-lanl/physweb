package HTML::FormHandler::Model::DBIC::TypeMap;
# ABSTRACT: type mape for DBICFields

use Moose;
use namespace::autoclean;


has 'data_type_map' => ( is => 'ro', isa => 'HashRef',
   lazy => 1, builder => 'build_data_type_map',
   traits => ['Hash'],
   handles => {
      get_field_type => 'get'
   },
);

sub build_data_type_map {
    my $self = shift;
    return {
        'varchar'   => 'Text',
        'text'      => 'TextArea',
        'integer'   => 'Integer',
        'int'       => 'Integer',
        'numeric'   => 'Integer',
        'datetime'  => 'DateTime',
        'timestamp' => 'DateTime',
        'bool'      => 'Boolean',
        'decimal'   => 'Float',
        'bigint'    => 'Integer',
        'enum'      => 'Select',
   };
}

sub type_for_column {
    my ( $self, $info ) = @_;

    my %field_def;
    my $type;
    if( my $def = $info->{extra}->{field_def} ) {
        return $def;
    }
    if( $info->{data_type} ) {
        $type = $self->get_field_type( lc($info->{data_type}) );
    }
    $type ||= 'Text';
    $field_def{type} = $type;
    $field_def{size} = $info->{size}
           if( $type eq 'Textarea' && $info->{size} );
    $field_def{required} = 1 if not $info->{is_nullable};
    return \%field_def;
}

# stub
sub type_for_rel {
    my ( $self, $rel ) = @_;
    return;
}

1;

__END__
=pod

=head1 NAME

HTML::FormHandler::Model::DBIC::TypeMap - type mape for DBICFields

=head1 VERSION

version 0.14

=head1 SYNOPSIS

Use by L<HTML::FormHandler::TraitFor::DBICFields>.

=head1 AUTHOR

FormHandler Contributors - see HTML::FormHandler

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Gerda Shank.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

