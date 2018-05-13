package ShopDb::Schema::Result::UserPreferences;

use strict;
use warnings;

use base 'ShopDb::Schema::Base';

=head1 NAME

ShopDb::Schema::Result::UserPreferences

=cut

__PACKAGE__->table("shopdb.user_preferences");

=head1 ACCESSORS

=head2 address_id

=cut

__PACKAGE__->add_columns(
  'preference_id',
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
  'directory_uid',
  {
    data_type => 'integer',
    default_value => undef,
    is_nullable => 0,
    is_foreign_key => 1,
  },
  'value',
  {
    data_type => 'varchar',
    default_value => undef,
    is_nullable => 0,
    size => '1024',
  },
);
__PACKAGE__->set_primary_key('preference_id');
__PACKAGE__->add_unique_constraint([ 'name', 'directory_uid' ]);

=head1 RELATIONS

=head2 directory_entry

Type: belongs_to

Related object: L<ShopDb::Schema::Result::DirectoryEntry>

=cut

__PACKAGE__->belongs_to(
  "directory",
  "ShopDb::Schema::Result::DirectoryEntry",
  { 'foreign.uid' => 'self.directory_uid' },
);

sub audit_description {
    my $self = shift;
    return '<user_preference>';
}

1;
