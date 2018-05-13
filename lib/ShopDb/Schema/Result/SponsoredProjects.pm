package ShopDb::Schema::Result::SponsoredProjects;

use strict;
use warnings;

use base 'ShopDb::Schema::Base';

=head1 NAME

ShopDb::Schema::Result::SponsoredProjects

=cut

__PACKAGE__->table("shopdb.sponsored_projects");

=head1 ACCESSORS

=head2 project_id

=head2 descr

=head2 eff_status

=head2 business_unit

=cut

__PACKAGE__->add_columns(
  'project_id',
  {
    data_type => 'varchar',
    default_value => undef,
    is_nullable => 0,
    size => 15,
  },
  'descr',
  {
    data_type => 'varchar',
    default_value => undef,
    is_nullable => 0,
    size => 255,
  },
  'eff_status',
  {
    data_type => 'varchar',
    default_value => undef,
    is_nullable => 0,
    size => 1,
  },
  'business_unit',
  {
    data_type => 'varchar',
    default_value => undef,
    is_nullable => 0,
    size => 5,
  },
);
__PACKAGE__->set_primary_key('project_id');

=head1 RELATIONS

=head2 accounts

Type: has_many

Related object: L<ShopDb::Schema::Result::Accounts>

=cut

__PACKAGE__->has_many(
  "accounts",
  "ShopDb::Schema::Result::Accounts",
  { 'foreign.project_id' => 'self.project_id' },
  { cascade_delete => 0, cascade_copy => 0 },
);

=head2 members

Type: has_many

Related object: L<ShopDb::Schema::Result::SponsoredProjectMembers>

=cut

__PACKAGE__->has_many(
  "members",
  "ShopDb::Schema::Result::SponsoredProjectMembers",
  { 'foreign.project_id' => 'self.project_id' },
  { cascade_delete => 0, cascade_copy => 0 },
);

sub audit_description {
    my $self = shift;
    return $self->descr;
}

1;
