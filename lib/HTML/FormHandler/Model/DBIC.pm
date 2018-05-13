package HTML::FormHandler::Model::DBIC;
# ABSTRACT: base class that holds DBIC model role

use Moose;
extends 'HTML::FormHandler';
with 'HTML::FormHandler::TraitFor::Model::DBIC';

our $VERSION = '0.14';


use namespace::autoclean;
1;

__END__
=pod

=head1 NAME

HTML::FormHandler::Model::DBIC - base class that holds DBIC model role

=head1 VERSION

version 0.14

=head1 SUMMARY

Empty base class - see L<HTML::FormHandler::TraitFor::Model::DBIC> for
documentation.

=head1 AUTHOR

FormHandler Contributors - see HTML::FormHandler

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Gerda Shank.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

