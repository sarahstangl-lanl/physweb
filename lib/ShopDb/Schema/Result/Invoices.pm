package ShopDb::Schema::Result::Invoices;

use strict;
use warnings;

use base 'ShopDb::Schema::Base';

=head1 NAME

ShopDb::Schema::Result::Invoices

=cut

__PACKAGE__->table("shopdb.invoices");

=head1 ACCESSORS

=head2 invoice_id

=head2 pdf

=head2 job_id

=head2 bill_date

=head2 paid_date

=head2 creation_date

=head2 creator_uid

=head2 account_key

=cut

__PACKAGE__->add_columns(
  'invoice_id',
  {
    data_type => 'varchar',
    default_value => undef,
    is_nullable => 0,
    is_auto_increment => 0,
    size => 30,
  },
  'job_id',
  {
    data_type => 'integer',
    default_value => undef,
    is_nullable => 0,
  },
  'pdf',
  {
    data_type => 'mediumblob', # 16MB limit
    default_value => undef,
    is_nullable => 0,
  },
  'bill_date',
  {
    data_type => 'date',
    default_value => undef,
    is_nullable => 1,
  },
  'paid_date',
  {
    data_type => 'date',
    default_value => undef,
    is_nullable => 1,
  },
  'creation_date',
  {
    data_type => 'date',
    default_value => undef,
    is_nullable => 0,
  },
  'creator_uid',
  {
    data_type => 'integer',
    default_value => undef,
    is_nullable => 0,
  },
  'account_key',
  {
    data_type => 'varchar',
    default_value => undef,
    is_nullable => 0,
    size => 255,
  },
);
__PACKAGE__->set_primary_key('invoice_id');

=head1 RELATIONS

=head2 job

Type: belongs_to

Related object: L<ShopDb::Schema::Result::Jobs>

=cut

__PACKAGE__->belongs_to(
  "job",
  "ShopDb::Schema::Result::Jobs",
  { 'foreign.job_id' => 'self.job_id' },
);

=head2 creator

Type: belongs_to

Related object: L<ShopDb::Schema::Result::DirectoryEntry>

=cut

__PACKAGE__->belongs_to(
  "creator",
  "ShopDb::Schema::Result::DirectoryEntry",
  { 'foreign.uid' => 'self.creator_uid' },
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

=head2 labor_lines

Type: has_many

Related object: L<ShopDb::Schema::Result::LaborLines>

=cut

__PACKAGE__->has_many(
  "labor_lines",
  "ShopDb::Schema::Result::LaborLines",
  { 'foreign.invoice_id' => 'self.invoice_id' },
  { cascade_delete => 0, cascade_copy => 0 },
);

=head2 material_lines

Type: has_many

Related object: L<ShopDb::Schema::Result::MaterialLines>

=cut

__PACKAGE__->has_many(
  "material_lines",
  "ShopDb::Schema::Result::MaterialLines",
  { 'foreign.invoice_id' => 'self.invoice_id' },
  { cascade_delete => 0, cascade_copy => 0 },
);

sub audit_description {
    my $self = shift;
    return 'Invoice #' . $self->invoice_id;
}

1;

