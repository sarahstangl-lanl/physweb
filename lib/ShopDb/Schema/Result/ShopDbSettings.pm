package ShopDb::Schema::Result::ShopDbSettings;

use strict;
use warnings;

use base 'ShopDb::Schema::Base';

=head1 NAME

ShopDb::Schema::Result::ShopDbSettings

=cut

__PACKAGE__->table("shopdb.shopdb_settings");

=head1 ACCESSORS

=head2 address_id

=cut

__PACKAGE__->add_columns(
  'setting_id',
  {
    data_type => 'integer',
    default_value => undef,
    is_nullable => 0,
    size => undef,
    is_auto_increment => 1,
  },
  'name',
  {
    data_type => 'varchar',
    default_value => undef,
    is_nullable => 0,
    size => '80',
  },
  'value',
  {
    data_type => 'varchar',
    default_value => undef,
    is_nullable => 0,
    size => '512',
  },
  'is_unique',
  {
    data_type => 'boolean',
    default_value => 1,
    is_nullable => 0,
    size => undef,
  },
);
__PACKAGE__->set_primary_key('setting_id');
__PACKAGE__->add_unique_constraint([ qw/name value/ ]);

sub audit_description {
    my $self = shift;
    return '<shopdb_setting>';
}

1;
