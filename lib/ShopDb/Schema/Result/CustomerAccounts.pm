package ShopDb::Schema::Result::CustomerAccounts;

use strict;
use warnings;

use base 'ShopDb::Schema::Base';

=head1 NAME

ShopDb::Schema::Result::CustomerAccounts

=cut

__PACKAGE__->table("shopdb.customer_accounts");

=head1 ACCESSORS

=head2 customer_account_id

=head2 account_key

=head2 customer_id

=cut

__PACKAGE__->add_columns(
  'customer_account_id',
  {
    data_type => 'integer',
    is_auto_increment => 1,
  },
  'account_key',
  {
    data_type => 'varchar',
    default_value => undef,
    is_foreign_key => 1,
    size => 255,
  },
  'customer_id',
  {
    data_type => 'integer',
    default_value => undef,
    is_foreign_key => 1,
    size => undef,
  },
);
__PACKAGE__->set_primary_key('customer_account_id');
__PACKAGE__->add_unique_constraint([ 'account_key', 'customer_id' ]);

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

=head2 account

Type: belongs_to

Related object: L<ShopDb::Schema::Result::Accounts>

=cut

__PACKAGE__->belongs_to(
  "account",
  "ShopDb::Schema::Result::Accounts",
  { 'foreign.account_key' => 'self.account_key' },
);

sub audit_description {
    my $self = shift;
    my $from_rel = shift;
    return '<customer desc>' if $from_rel eq 'Accounts';
    return '<account desc>';
}

1;
