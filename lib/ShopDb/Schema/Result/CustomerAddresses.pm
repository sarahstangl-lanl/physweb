package ShopDb::Schema::Result::CustomerAddresses;

use strict;
use warnings;

use base 'ShopDb::Schema::Base';

=head1 NAME

ShopDb::Schema::Result::CustomerAddresses

=cut

__PACKAGE__->table("shopdb.customer_addresses");

=head1 ACCESSORS

=head2 customer_address_id

=head2 address_id

=head2 customer_id

=cut

__PACKAGE__->add_columns(
  'customer_address_id',
  {
    data_type => 'integer',
    is_auto_increment => 1,
  },
  'address_id',
  {
    data_type => 'integer',
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 1,
    size => undef,
  },
  'customer_id',
  {
    data_type => 'integer',
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 1,
    size => undef,
  },
);
__PACKAGE__->set_primary_key('customer_address_id');
__PACKAGE__->add_unique_constraint([ 'address_id', 'customer_id' ]);

=head1 RELATIONS

=head2 customer

Type: belongs_to

Related object: L<ShopDb::Schema::Result::Customers>

=cut

__PACKAGE__->belongs_to(
  "customer",
  "ShopDb::Schema::Result::Customers",
  { 'foreign.customer_id' => 'self.customer_id' },
);

=head2 address

Type: belongs_to

Related object: L<ShopDb::Schema::Result::Addresses>

=cut

__PACKAGE__->belongs_to(
  "address",
  "ShopDb::Schema::Result::Addresses",
  { 'foreign.address_id' => 'self.address_id' },
);

sub audit_description {
    my $self = shift;
    my $from_rel = shift;
    return '<customer desc>' if $from_rel eq 'Addresses';
    return '<address desc>';
}

1;
