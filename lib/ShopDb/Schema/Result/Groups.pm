package ShopDb::Schema::Result::Groups;

use strict;
use warnings;

use base 'ShopDb::Schema::Base';

=head1 NAME

ShopDb::Schema::Result::Groups

=cut

#__PACKAGE__->load_components(qw/InflateColumn::Object::Enum/);
__PACKAGE__->table("webdb.groups");

=head1 ACCESSORS

=head2 name

=head2 description

=head2 purpose

=head2 type

=cut

__PACKAGE__->add_columns(
  'name',
  {
    data_type => 'varchar',
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 1,
    size => '50',
  },
  'description',
  {
    data_type => 'varchar',
    default_value => undef,
    is_nullable => 1,
    size => '250',
  },
  'purpose',
  {
    data_type => 'varchar',
    default_value => undef,
    is_nullable => 1,
    size => '250',
  },
  'type',
  {
    data_type => 'enum',
    default_value => undef,
    is_nullable => 1,
    is_enum => 1,
    size => '10',
    extra => {
        list => [qw/auth flags rgroup labgroup committee facultytype machinegroup dooraccess web globaldoorgroup/],
    },
  },
);
__PACKAGE__->set_primary_key('name');

=head1 RELATIONS

=head2 customers

Type: many_to_many

Related object: L<ShopDb::Schema::Result::Customers>

=cut

__PACKAGE__->has_many(
  "group_members",
  "ShopDb::Schema::Result::GroupMembers",
  { "foreign.groupname" => "self.name" },
  { cascade_delete => 0, cascade_copy => 0 },
);

__PACKAGE__->many_to_many(
  "customers",
  'group_members',
  'customer',
);

sub audit_description {
    my $self = shift;
    return $self->name;
}

1;
