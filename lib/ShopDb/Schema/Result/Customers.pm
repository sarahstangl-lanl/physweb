package ShopDb::Schema::Result::Customers;

use strict;
use warnings;

use base 'ShopDb::Schema::Base';


=head1 NAME

ShopDb::Schema::Result::Customers

=cut

__PACKAGE__->table("shopdb.customers");

=head1 ACCESSORS

=head2 customer_id

=head2 directory_uid

=head2 title

=head2 company_name

=head2 comments

=head2 primary_ship_address

=head2 primary_bill_address

=cut

__PACKAGE__->add_columns(
  'customer_id',
  {
    data_type => 'integer',
    default_value => undef,
    is_nullable => 1,
    size => undef,
    is_auto_increment => 1,
  },
  'directory_uid',
  {
    data_type => 'integer',
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 0,
    size => undef,
  },
  'customer_type_id',
  {
    data_type => 'integer',
    default_value => 1,
    is_foreign_key => 1,
    is_nullable => 0,
    size => undef,
  },
  'title',
  {
    data_type => 'varchar',
    default_value => undef,
    is_nullable => 1,
    size => '255',
  },
  'company_name',
  {
    data_type => 'varchar',
    default_value => undef,
    is_nullable => 1,
    size => '1024',
  },
  'comments',
  {
    data_type => 'varchar',
    default_value => undef,
    is_nullable => 1,
    size => '1024',
  },
  'fax_number',
  {
    data_type => 'varchar',
    default_value => undef,
    is_nullable => 1,
    size => '255',
  },
  'primary_ship_address',
  {
    data_type => 'integer',
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 1,
    size => undef,
  },
  'primary_bill_address',
  {
    data_type => 'integer',
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 1,
    size => undef,
  },
);
__PACKAGE__->set_primary_key('customer_id');
__PACKAGE__->add_unique_constraint(['directory_uid']);

=head1 RELATIONS

=head2 jobs

Type: has_many

Related object: L<ShopDb::Schema::Result::Jobs>

=cut

__PACKAGE__->has_many(
  "jobs",
  "ShopDb::Schema::Result::Jobs",
  [ { 'foreign.customer_id' => 'self.customer_id' },
    { 'foreign.pi_id' => 'self.customer_id' } ],
  { cascade_delete => 0, cascade_copy => 0 },
);

=head2 customer_addresses

Type: has_many

Related object: L<ShopDb::Schema::Result::CustomerAddresses>

=cut

__PACKAGE__->has_many(
  "customer_addresses",
  "ShopDb::Schema::Result::CustomerAddresses",
  { 'foreign.customer_id' => 'self.customer_id' },
  { cascade_delete => 0, cascade_copy => 0 },
);

=head2 addresses

Type: many_to_many

Related object: L<ShopDb::Schema::Result::Addresses>

=cut
 
__PACKAGE__->many_to_many(
  "addresses",
  "customer_addresses",
  "address",
);

=head2 customer_accounts

Type: has_many

Related object: L<ShopDb::Schema::Result::CustomerAccounts>

=cut

__PACKAGE__->has_many(
  "customer_accounts",
  "ShopDb::Schema::Result::CustomerAccounts",
  { 'foreign.customer_id' => 'self.customer_id' },
  { cascade_delete => 0, cascade_copy => 0 },
);

=head2 accounts

Type: many_to_many

Related object: L<ShopDb::Schema::Result::Accounts>

=cut

__PACKAGE__->many_to_many(
  "accounts",
  "customer_accounts",
  "account",
);

=head2 directory

Type: belongs_to

Related object: L<ShopDb::Schema::Result::DirectoryEntry>

=cut

__PACKAGE__->belongs_to(
  "directory",
  "ShopDb::Schema::Result::DirectoryEntry",
  { 'foreign.uid' => 'self.directory_uid' },
  { 'is_foreign_key_constraint' => 0 },
);

=head2 customer_type

Type: belongs_to

Related object: L<ShopDb::Schema::Result::CustomerTypes>

=cut

__PACKAGE__->belongs_to(
  "customer_type",
  "ShopDb::Schema::Result::CustomerTypes",
  { 'foreign.customer_type_id' => 'self.customer_type_id' },
);

=head2 ship_address

Type: belongs_to

Related object: L<ShopDb::Schema::Result::Addresses>

=cut

__PACKAGE__->belongs_to(
  "ship_address",
  "ShopDb::Schema::Result::Addresses",
  { 'foreign.address_id' => 'self.primary_ship_address' },
  { join_type => 'left' },
);

=head2 bill_address

Type: belongs_to

Related object: L<ShopDb::Schema::Result::Addresses>

=cut

__PACKAGE__->belongs_to(
  "bill_address",
  "ShopDb::Schema::Result::Addresses",
  { 'foreign.address_id' => 'self.primary_bill_address' },
  { join_type => 'left' },
);

=head2 group_members

Type: has_many

Related object: L<ShopDb::Schema::Result::GroupMembers>

=cut

__PACKAGE__->has_many(
  "group_members",
  "ShopDb::Schema::Result::GroupMembers",
  { 'foreign.uid' => 'self.directory_uid' },
  { cascade_delete => 0, cascade_copy => 0 },
);

=head2 groups

Type: many_to_many

Related object: L<ShopDb::Schema::Result::Groups>

=cut

__PACKAGE__->many_to_many(
  "groups",
  "group_members",
  "group",
);

=head2 attachments

Type: has_many

Related object: L<ShopDb::Schema::Result::Attachments>

=cut

__PACKAGE__->has_many(
  "attachments",
  "ShopDb::Schema::Result::Attachments",
  { 'foreign.uploader_uid' => 'self.directory_uid' },
  { cascade_delete => 0, cascade_copy => 0 },
);

sub shopdb {
    my $self = shift;
    return $self->find_related('group_members', { groupname => 'shopdb' } ) ? 1 : 0;
}

sub audit_description {
    my $self = shift;
    return $self->directory->display_name;
}

1;
