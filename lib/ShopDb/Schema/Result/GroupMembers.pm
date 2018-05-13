package ShopDb::Schema::Result::GroupMembers;

use strict;
use warnings;

use base 'ShopDb::Schema::Base';

=head1 NAME

ShopDb::Schema::Result::GroupMembers

=cut

__PACKAGE__->table("webdb.groupmembers");

=head1 ACCESSORS

=head2

=head2

=cut

__PACKAGE__->add_columns(
  'uid',
  {
    data_type => 'integer',
    default_value => undef,
    is_nullable => 1,
    is_foreign_key => 1,
    size => undef,
  },
  'groupname',
  {
    data_type => 'varchar',
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 1,
    size => '50',
  },
);
__PACKAGE__->set_primary_key('groupname','uid');

=head1 RELATIONS

=head2 customer

Type: belongs_to

Related object: L<ShopDb::Schema::Result::Customers>

=cut

__PACKAGE__->belongs_to(
  "customer",
  "ShopDb::Schema::Result::Customers",
  { 'foreign.directory_uid' => 'self.uid' },
);

=head2 group

Type: belongs_to

Related object: L<ShopDb::Schema::Result::Groups>

=cut

__PACKAGE__->belongs_to(
  "group",
  "ShopDb::Schema::Result::Groups",
  { 'foreign.name' => 'self.groupname' },
);

sub audit_description {
    my $self = shift;
    my $from_rel = shift;
    return $self->customer->audit_description if $from_rel eq 'Groups';
    return $self->group->audit_description;
}

1;
