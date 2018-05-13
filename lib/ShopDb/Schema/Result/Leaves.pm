package ShopDb::Schema::Result::Leaves;

use strict;
use warnings;

use base 'ShopDb::Schema::Base';


=head1 NAME

ShopDb::Schema::Result::Leaves

=cut

__PACKAGE__->table('shopdb.leaves');

=head1 ACCESSORS

=head2 leave_id

=head2 machinist_id

=head2 leave_type_id

=head2 hours

=head2 date

=cut

__PACKAGE__->add_columns(
  'leave_id',
  {
    data_type => 'integer',
    default_value => undef,
    is_nullable => 0,
    size => undef,
    is_auto_increment => 1,
  },
  'machinist_id',
  {
    data_type => 'integer',
    default_value => undef,
    is_nullable => 0,
    size => undef,
    is_foreign_key => 1,
  },
  'hours',
  {
    data_type => 'float',
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
  'leave_type_id',
  {
    data_type => 'integer',
    default_value => undef,
    is_nullable => 0,
    is_foreign_key => 1,
    size => undef,
  },
  'date',
  {
    data_type => 'date',
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
);
__PACKAGE__->set_primary_key('leave_id');

=head1 RELATIONS

=head2 leave_type

Type: belongs_to

Related object: L<ShopDb::Schema::Result::LeaveTypes>

=cut

__PACKAGE__->belongs_to(
  'leave_type',
  'ShopDb::Schema::Result::LeaveTypes',
  { 'foreign.leave_type_id' => 'self.leave_type_id' },
);

=head2 machinist

Type: belongs_to

Related object: L<ShopDb::Schema::Result::Machinists>

=cut

__PACKAGE__->belongs_to(
  'machinist',
  'ShopDb::Schema::Result::Machinists',
  { 'foreign.machinist_id' => 'self.machinist_id' },
);

1;
