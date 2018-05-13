package ShopDb::Schema::Result::SponsoredProjectMembers;

use strict;
use warnings;

use base 'ShopDb::Schema::Base';

=head1 NAME

ShopDb::Schema::Result::SponsoredProjectMembers

=cut

__PACKAGE__->table("shopdb.sponsored_project_members");

=head1 ACCESSORS

=head2 project_id

=head2 team_member

=head2 proj_role

=cut

__PACKAGE__->add_columns(
  'project_id',
  {
    data_type => 'varchar',
    default_value => undef,
    is_nullable => 0,
    size => 15,
    is_auto_increment => 0,
  },
  'team_member',
  {
    data_type => 'varchar',
    default_value => undef,
    is_nullable => 0,
    size => 31,
  },
  'proj_role',
  {
    data_type => 'varchar',
    default_value => undef,
    is_nullable => 0,
    size => 16,
  },
);
__PACKAGE__->set_primary_key('project_id','team_member');

=head1 RELATIONS

=head2 accounts

Type: has_many

Related object: L<ShopDb::Schema::Result::Accounts>

=cut

__PACKAGE__->has_many(
  "accounts",
  "ShopDb::Schema::Result::Accounts",
  { 'foreign.project_id' => 'self.project_id' },
);

=head2 project

Type: belongs_to

Related object: L<ShopDb::Schema::Result::SponsoredProjects>

=cut

__PACKAGE__->belongs_to(
  "project",
  "ShopDb::Schema::Result::SponsoredProjects",
  { 'foreign.project_id' => 'self.project_id' },
);

=head2 directory

Type: belongs_to

Related object: L<ShopDb::Schema::Result::DirectoryEntry>

=cut

__PACKAGE__->belongs_to(
  "directory",
  "ShopDb::Schema::Result::DirectoryEntry",
  { 'foreign.emplid' => 'self.team_member' },
  { 'join_type' => 'left' },
);

sub audit_description {
    my $self = shift;
    return $self->proj_role . ': ' . $self->team_member;
}

1;
