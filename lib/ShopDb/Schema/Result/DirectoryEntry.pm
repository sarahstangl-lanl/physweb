package ShopDb::Schema::Result::DirectoryEntry;

use strict;
use warnings;

use base 'ShopDb::Schema::Base';

=head1 NAME

ShopDb::Schema::Result::DirectoryEntry

=cut

__PACKAGE__->table("webdb.directory");

=head1 ACCESSORS

=head2 uid

=head2 last_name

=head2 first_name

=head2 physid

=head2 x500

=head2 email

=head2 room

=head2 work_phone

=head2 cell_phone

=head2 create_date

=head2 modified_date

=cut

__PACKAGE__->add_columns(
  'uid',
  {
    data_type => 'integer',
    default_value => undef,
    size => undef,
    is_auto_increment => 1,
  },
  'emplid',
  {
    data_type => 'varchar',
    default_value => undef,
    is_nullable => 1,
    size => '11',
  },
  'last_name',
  {
    data_type => 'varchar',
    default_value => '',
    is_nullable => 0,
    size => '80',
  },
  'first_name',
  {
    data_type => 'varchar',
    default_value => '',
    is_nullable => 0,
    size => '80',
  },
  'physid',
  {
    data_type => 'varchar',
    default_value => undef,
    is_nullable => 1,
    size => '16',
  },
  'x500',
  {
    data_type => 'varchar',
    default_value => '',
    is_nullable => 0,
    size => '10',
  },
  'email',
  {
    data_type => 'varchar',
    default_value => '',
    is_nullable => 0,
    size => '100',
  },
  'room',
  {
    data_type => 'varchar',
    default_value => '',
    is_nullable => 0,
    size => '50',
  },
  'work_phone',
  {
    data_type => 'varchar',
    default_value => '',
    is_nullable => 0,
    size => '40',
  },
  'cell_phone',
  {
    data_type => 'varchar',
    default_value => '',
    is_nullable => 0,
    size => '20',
  },
  'position',
  {
    data_type => 'varchar',
    default_value => '',
    is_nullable => 0,
    size => 100,
  },
  'create_date',
  {
    data_type => 'datetime',
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
  'modified_date',
  {
    data_type => 'datetime',
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
);
__PACKAGE__->set_primary_key('uid');

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

=head2 group_memberships

Type: has_many

Related object: L<ShopDb::Schema::Result::GroupMembers>

=cut

__PACKAGE__->has_many(
  "group_memberships",
  "ShopDb::Schema::Result::GroupMembers",
  { 'foreign.uid' => 'self.uid' },
  { cascade_delete => 0, cascade_copy => 0 },
);

=head2 groups

Type: many_to_many

Related object: L<ShopDb::Schema::Result::Groups>

=cut

__PACKAGE__->many_to_many(
  "groups",
  "group_memberships",
  "group",
);

=head2 machinist

Type: belongs_to

Related object: L<ShopDb::Schema::Result::Machinsts>

=cut

__PACKAGE__->belongs_to(
  "machinist",
  "ShopDb::Schema::Result::Machinists",
  { 'foreign.directory_uid' => 'self.uid' },
);

sub display_name {
    my $self = shift;
    return $self->last_name . ', ' . $self->first_name;
}

sub full_name {
    my $self = shift;
    return $self->first_name . ' ' . $self->last_name;
}

sub audit_description {
    my $self = shift;
    return $self->display_name;
}

# Override insert to force create_date to be set add user to shopdb group if new entry
sub insert {
    my $self = shift;
    my $entry_exists = $self->in_storage;
    $self->create_date(\'NOW()');
    $self->modified_date(\'NOW()');
    $self->position('Shop customer');
    my $return = $self->next::method(@_);
    $self->create_related('group_memberships', { groupname => 'shopdb' }) unless $entry_exists;
    return $return;
}

sub update {
    my $self = shift;
    $self->modified_date(\'NOW()') if ($self->is_changed);
    $self->next::method(@_);
}

1;
