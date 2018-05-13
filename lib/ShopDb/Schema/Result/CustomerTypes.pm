package ShopDb::Schema::Result::CustomerTypes;

use strict;
use warnings;

use base 'ShopDb::Schema::Base';

__PACKAGE__->table("shopdb.customer_types");

=head1 ACCESSORS

=head2 customer_type_id

=head2 label

=head2 sort_order

=cut

__PACKAGE__->add_columns(
  "customer_type_id",
  {
    data_type => "integer",
    default_value => undef,
    size => undef,
    is_auto_increment => 1,
  },
  "label",
  {
    data_type => "varchar",
    default_value => undef,
    size => 255,
    is_nullable => 0,
  },
  "sort_order",
  {
    data_type => "integer",
    default_value => 0,
    size => undef,
    is_nullable => 0,
  },
);
__PACKAGE__->set_primary_key("customer_type_id");

=head1 RELATIONS

=head2 customers

Type: has_many

Related object: L<ShopDb::Schema::Result::Customers>

=cut

__PACKAGE__->has_many(
  "customers",
  "ShopDb::Schema::Result::Customers",
  { 'foreign.customer_type_id' => 'self.customer_type_id' },
  { cascade_delete => 0, cascade_copy => 0 },
);

sub audit_description {
    my $self = shift;
    return $self->label;
}

1;
