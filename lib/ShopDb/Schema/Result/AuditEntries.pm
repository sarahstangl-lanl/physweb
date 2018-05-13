package ShopDb::Schema::Result::AuditEntries;

use strict;
use warnings;

use base 'ShopDb::Schema::Base';

=head1 NAME

ShopDb::Schema::Result::AuditEntries

=cut

__PACKAGE__->table("shopdb.audit_entries");

=head1 ACCESSORS

=head2 entry_id

=head2 directory_uid

=head2 result_type

=head2 result_id

=head2 action_type

=head2 value

=head2 entry_date

=cut

__PACKAGE__->add_columns(
  'entry_id',
  {
    data_type => 'integer',
    default_value => undef,
    is_nullable => 0,
    is_auto_increment => 1,
  },
  'directory_uid',
  {
    data_type => 'integer',
    default_value => undef,
    is_nullable => 0,
  },
  'result_type',
  {
    data_type => 'varchar',
    default_value => undef,
    is_nullable => 0,
    size => 255,
  },
  'result_id',
  {
    data_type => 'varchar',
    default_value => undef,
    is_nullable => 0,
    size => '255',
  },
  'action_type',
  {
    data_type => 'varchar',
    default_value => undef,
    is_nullable => 0,
    size => 255,
  },
  'value',
  {
    data_type => 'varchar',
    default_value => undef,
    is_nullable => 0,
    size => 2048,
  },
  'entry_date',
  {
    data_type => 'datetime',
    is_nullable => 0,
  },
);
__PACKAGE__->set_primary_key('entry_id');

=head1 RELATIONS

=head2 directory

Type: belongs_to

Related object: L<ShopDb::Schema::Result::DirectoryEntry>

=cut

__PACKAGE__->belongs_to(
  "directory",
  "ShopDb::Schema::Result::DirectoryEntry",
  { 'foreign.uid' => 'self.directory_uid' },
);


sub new {
    my ($self, $attrs) = @_;

    # Ensure entry_date is set to NOW()
    $attrs->{entry_date} = \'NOW()' unless (defined $attrs->{entry_date});

    return $self->next::method($attrs);
}

sub update {
    die "Audit entries cannot be modified";
}

sub delete {
    die "Audit entries cannot be deleted";
}

sub audit_description {
    my $self = shift;
    $self->value;
}

1;
