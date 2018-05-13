package ShopDb::Schema::Result::Addresses;

use strict;
use warnings;

use base 'ShopDb::Schema::Base';

=head1 NAME

ShopDb::Schema::Result::Addresses

=cut

__PACKAGE__->table("shopdb.addresses");

=head1 ACCESSORS

=head2 address_id

=head2 company

=head2 lines

=cut

__PACKAGE__->add_columns(
  'address_id',
  {
    data_type => 'integer',
    default_value => undef,
    is_nullable => 1,
    size => undef,
    is_auto_increment => 1,
  },
  'company',
  {
    data_type => 'varchar',
    default_value => undef,
    is_nullable => 1,
    size => '256',
  },
  'lines',
  {
    data_type => 'varchar',
    default_value => undef,
    is_nullable => 1,
    size => '32768',
  },
);
__PACKAGE__->set_primary_key('address_id');

=head1 RELATIONS

=head2 customer_addresses

Type: has_many

Related object: L<ShopDb::Schema::Result::CustomerAddresses>

=cut

__PACKAGE__->has_many(
  "customer_addresses",
  "ShopDb::Schema::Result::CustomerAddresses",
  { 'foreign.address_id' => 'self.address_id' },
  { cascade_delete => 0, cascade_copy => 0 },
);

=head2 customers

Type: many_to_many

Related object: L<ShopDb::Schema::Result::Customers>

=cut

__PACKAGE__->many_to_many(
  "customers",
  "customer_addresses",
  "customer",
);

=head2 jobs

Type: has_many

Related object: L<ShopDb::Schema::Result::Jobs>

=cut

__PACKAGE__->has_many(
    "jobs",
    "ShopDb::Schema::Result::Jobs",
    [
        { 'foreign.ship_address_id' => 'self.address_id' },
        { 'foreign.bill_address_id' => 'self.address_id' },
    ],
    { cascade_delete => 0, cascade_copy => 0 },
);

=head2 packing_slips

Type: has_many

Related object: L<ShopDb::Schema::Result::PackingSlips>

=cut

__PACKAGE__->has_many(
    "packing_slips",
    "ShopDb::Schema::Result::PackingSlips",
    { 'foreign.ship_address_id' => 'self.address_id' },
    { cascade_delete => 0, cascade_copy => 0 },
);

sub to_string {
    my $self = shift;
    return join("\n", $self->company, $self->lines);
}

sub audit_description {
    my $self = shift;
    return '<addresss desc>';
}

1;
