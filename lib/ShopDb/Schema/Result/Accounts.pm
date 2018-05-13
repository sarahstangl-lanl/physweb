package ShopDb::Schema::Result::Accounts;

use strict;
use warnings;

use base 'ShopDb::Schema::Base';

=head1 NAME

ShopDb::Schema::Result::Accounts

=cut

__PACKAGE__->table("shopdb.accounts");

=head1 ACCESSORS

=head2 account_key

=head2 account_type_id

=head2 setid

=head2 fund_code

=head2 deptid

=head2 program_code

=head2 project_id

=head2 chartfield3

=head2 chartfield1

=head2 chartfield2

=head2 descr50

=head2 lastupddttm

=head2 lastupdoprid

=head2 disabled

=head2 comment

=cut

__PACKAGE__->add_columns(
  'account_key',
  {
    data_type => 'varchar',
    default_value => undef,
    is_nullable => 0,
    size => 255,
    is_auto_increment => 0,
  },
  'account_type_id',
  {
    data_type => 'integer',
    default_value => 1,
    is_nullable => 0,
    is_foreign_key => 1,
    size => undef,
  },
  'setid',
  {
    data_type => 'varchar',
    default_value => undef,
    is_nullable => 1,
    size => 9,
  },
  'fund_code',
  {
    data_type => 'varchar',
    default_value => undef,
    is_nullable => 1,
    size => 5,
  },
  'deptid',
  {
    data_type => 'varchar',
    default_value => undef,
    is_nullable => 1,
    size => 10,
  },
  'program_code',
  {
    data_type => 'varchar',
    default_value => undef,
    is_nullable => 1,
    size => 5,
  },
  'project_id',
  {
    data_type => 'varchar',
    default_value => undef,
    is_nullable => 1,
    size => 15,
  },
  'chartfield3',
  {
    data_type => 'varchar',
    default_value => undef,
    is_nullable => 1,
    size => 10,
  },
  'chartfield1',
  {
    data_type => 'varchar',
    default_value => undef,
    is_nullable => 1,
    size => 10,
  },
  'chartfield2',
  {
    data_type => 'varchar',
    default_value => undef,
    is_nullable => 1,
    size => 10,
  },
  'descr50',
  {
    data_type => 'varchar',
    default_value => undef,
    is_nullable => 1,
    size => 50,
  },
  'lastupddttm',
  {
    data_type => 'date',
    default_value => undef,
    is_nullable => 1,
  },
  'lastupdoprid',
  {
    data_type => 'varchar',
    default_value => undef,
    is_nullable => 1,
    size => 10,
  },
  'auto-added',
  {
    accessor => 'auto_added',
    data_type => 'boolean',
    default_value => 0,
    is_nullable => 0,
    size => 1,
  },
  'disabled',
  {
    data_type => 'boolean',
    default_value => 0,
    is_nullable => 0,
    size => 1,
  },
  'comment',
  {
    data_type => 'varchar',
    default_value => undef,
    size => 256,
    is_nullable => 1,
  },
);
__PACKAGE__->set_primary_key('account_key');
__PACKAGE__->add_unique_constraint([ qw/setid fund_code deptid program_code project_id chartfield3 chartfield1 chartfield2/ ]);

=head1 RELATIONS

=head2 customer_accounts

Type: has_many

Related object: L<ShopDb::Schema::Result::CustomerAccounts>

=cut

__PACKAGE__->has_many(
  "customer_accounts",
  "ShopDb::Schema::Result::CustomerAccounts",
  { 'foreign.account_key' => 'self.account_key' },
  { cascade_delete => 0, cascade_copy => 0 },
);

=head2 accounts

Type: many_to_many

Related object: L<ShopDb::Schema::Result::Customers>

=cut

__PACKAGE__->many_to_many(
  "customers",
  "customer_accounts",
  "customers",
);

=head2 project_members

Type: has_many

Related object: L<ShopDb::Schema::Result::SponsoredProjectMembers>

=cut

__PACKAGE__->has_many(
  "project_members",
  "ShopDb::Schema::Result::SponsoredProjectMembers",
  { 'foreign.project_id' => 'self.project_id' },
  { cascade_delete => 0, cascade_copy => 0 },
);

=head2 account_type

Type: belongs_to

Related object: L<ShopDb::Schema::Result::AccountTypes>

=cut

__PACKAGE__->belongs_to(
  "account_type",
  "ShopDb::Schema::Result::AccountTypes",
  { 'foreign.account_type_id' => 'self.account_type_id' },
);

=head2 project

Type: belongs_to

Related object: L<ShopDb::Schema::Result::SponsoredProjects>

=cut

__PACKAGE__->belongs_to(
  "project",
  "ShopDb::Schema::Result::SponsoredProjects",
  { 'foreign.project_id' => 'self.project_id' },
  { join_type => 'left', is_foreign_key_constraint => 0 },
);

sub insert {
    my ($self, @updates) = @_;
    $self->account_key(join(';', map { $self->$_ } (qw/setid fund_code deptid program_code project_id chartfield3 chartfield1 chartfield2/)));
    $self->next::method(@updates);
}

sub update {
    my ($self, @updates) = @_;
    delete $self->{_dirty_columns}->{account_key}
        if (exists $self->{_dirty_columns}->{account_key});
    $self->next::method(@updates);
}

sub audit_description {
    my $self = shift;
    return $self->descr50;
}

1;
