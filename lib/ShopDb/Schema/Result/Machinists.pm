package ShopDb::Schema::Result::Machinists;

use strict;
use warnings;

use base 'ShopDb::Schema::Base';


=head1 NAME

ShopDb::Schema::Result::Machinists

=cut

__PACKAGE__->table('shopdb.machinists');

=head1 ACCESSORS

=head2 machinist_id

=head2 directory_uid

=head2 labor_rate

=head2 shortname

=head2 fulltime

=head2 active

=cut

__PACKAGE__->add_columns(
  'machinist_id',
  {
    data_type => 'integer',
    default_value => undef,
    is_nullable => 0,
    size => undef,
    is_auto_increment => 1,
  },
  'directory_uid',
  {
    data_type => 'integer',
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 0,
    size => undef,
  },
  'labor_rate',
  {
    data_type => 'float',
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
  'shortname',
  {
    data_type => 'varchar',
    default_value => undef,
    is_nullable => 0,
    size => '5',
  },
  'fulltime',
  {
    data_type => 'boolean',
    default_value => 0,
    is_nullable => 0,
    size => undef,
  },
  'active',
  {
    data_type => 'boolean',
    default_value => 1,
    is_nullable => 0,
    size => undef,
  },
);
__PACKAGE__->set_primary_key('machinist_id');
__PACKAGE__->add_unique_constraint(['shortname']);

=head1 RELATIONS

=head2 directory_entry

Type: belongs_to

Related object: L<ShopDb::Schema::Result::DirectoryEntry>

=cut

__PACKAGE__->belongs_to(
  'directory',
  'ShopDb::Schema::Result::DirectoryEntry',
  { 'foreign.uid' => 'self.directory_uid' },
  { 'is_foreign_key_constraint' => 0 },
);

=head2 labor_lines

Type: has_many

Related object: L<ShopDb::Schema::Result::LaborLines>

=cut

__PACKAGE__->has_many(
  'labor_lines',
  'ShopDb::Schema::Result::LaborLines',
  { 'foreign.machinist_id' => 'self.machinist_id' },
  { cascade_delete => 0, cascade_copy => 0 },
);

=head2 material_lines

Type: has_many

Related object: L<ShopDb::Schema::Result::MaterialLines>

=cut

__PACKAGE__->has_many(
  'material_lines',
  'ShopDb::Schema::Result::MaterialLines',
  { 'foreign.machinist_id' => 'self.machinist_id' },
  { cascade_delete => 0, cascade_copy => 0 },
);

=head2 leaves

Type: has_many

Related object: L<ShopDb::Schema::Result::Leaves>

=cut

__PACKAGE__->has_many(
  'leaves',
  'ShopDb::Schema::Result::Leaves',
  { 'foreign.machinist_id' => 'self.machinist_id' },
  { cascade_delete => 0, cascade_copy => 0 },
);

=head2 jobs

Type: many_to_many

Related object: L<ShopDb::Schema::Result::Jobs>

=cut

__PACKAGE__->has_many(
  'job_assignments',
  'ShopDb::Schema::Result::JobAssignments',
  { 'foreign.machinist_id' => 'self.machinist_id' },
  { cascade_delete => 0, cascade_copy => 0 },
);

__PACKAGE__->many_to_many(
  'jobs',
  'job_assignments' => 'job',
);

sub audit_description {
    my $self = shift;
    return $self->directory->audit_description;
}

1;
