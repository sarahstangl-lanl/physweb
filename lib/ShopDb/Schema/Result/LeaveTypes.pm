package ShopDb::Schema::Result::LeaveTypes;

use strict;
use warnings;

use base 'ShopDb::Schema::Base';


=head1 NAME

ShopDb::Schema::Result::LeaveTypes

=cut

__PACKAGE__->table('shopdb.leave_types');

=head1 ACCESSORS

=head2 leave_type_id

=head2 label

=cut

__PACKAGE__->add_columns(
  'leave_type_id',
  {
    data_type => 'integer',
    default_value => undef,
    is_nullable => 0,
    size => undef,
    is_auto_increment => 1,
  },
  'label',
  {
    data_type => 'varchar',
    default_value => undef,
    is_nullable => 0,
    size => 32,
  },
);
__PACKAGE__->set_primary_key('leave_type_id');

=head1 RELATIONS

=head2 leaves

Type: has_many

Related object: L<ShopDb::Schema::Result::Leaves>

=cut

__PACKAGE__->has_many(
  'leaves',
  'ShopDb::Schema::Result::Leaves',
  { 'foreign.leave_type_id' => 'self.leave_type_id' },
  { cascade_delete => 0, cascade_copy => 0 },
);

1;
