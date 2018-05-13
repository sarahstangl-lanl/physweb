package ShopDb::Schema::Result::AccountTypes;

use strict;
use warnings;

use base 'ShopDb::Schema::Base';

__PACKAGE__->table("shopdb.account_types");

=head1 ACCESSORS

=head2 account_type_id

=head2 internal

=head2 label

=head2 sort_order

=cut

__PACKAGE__->add_columns(
  "account_type_id",
  {
    data_type => "integer",
    default_value => undef,
    size => undef,
    is_auto_increment => 1,
  },
  "internal",
  {
    data_type => "tinyint",
    default_value => 1,
    is_nullable => 0,
    size => 1,
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
__PACKAGE__->set_primary_key("account_type_id");

=head1 RELATIONS

=head2 accounts

Type: has_many

Related object: L<ShopDb::Schema::Result::Accounts>

=cut

__PACKAGE__->has_many(
  "accounts",
  "ShopDb::Schema::Result::Accounts",
  { 'foreign.account_type_id' => 'self.account_type_id' },
  { cascade_delete => 0, cascade_copy => 0 },
);

sub audit_description {
    my $self = shift;
    return $self->label;
}

1;
