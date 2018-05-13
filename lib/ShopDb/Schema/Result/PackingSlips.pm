package ShopDb::Schema::Result::PackingSlips;

use strict;
use warnings;

use base 'ShopDb::Schema::Base';

=head1 NAME

ShopDb::Schema::Result::PackingSlips

=cut

__PACKAGE__->table("shopdb.packing_slips");

=head1 ACCESSORS

=head2 packing_slip_id

=head2 pdf

=head2 job_id

=head2 ship_via

=head2 ship_reference

=head2 ship_address_id

=head2 quantity_shipped

=head2 ship_date

=head2 creator_uid

=cut

__PACKAGE__->add_columns(
  'packing_slip_id',
  {
    data_type => 'integer',
    default_value => undef,
    is_nullable => 0,
    is_auto_increment => 1,
  },
  'job_id',
  {
    data_type => 'integer',
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 0,
  },
  'pdf',
  {
    data_type => 'mediumblob', # 16MB limit
    default_value => undef,
    is_nullable => 0,
  },
  'ship_via',
  {
    data_type => 'varchar',
    default_value => undef,
    is_nullable => 0,
    size => 255,
  },
  'ship_reference',
  {
    data_type => 'varchar',
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  'ship_address_id',
  {
    data_type => 'integer',
    default_value => undef,
    is_nullable => 1,
    is_foreign_key => 1,
  },
  'quantity_shipped',
  {
    data_type => 'integer',
    default_value => undef,
    is_nullable => 0,
  },
  'ship_date',
  {
    data_type => 'date',
    default_value => undef,
    is_nullable => 1,
  },
  'creator_uid',
  {
    data_type => 'integer',
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 0,
  },
);
__PACKAGE__->set_primary_key('packing_slip_id');

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

=head2 lines

Type: has_many

Related object: L<ShopDb::Schema::Result::PackingSlipLines>

=cut

__PACKAGE__->has_many(
  "lines",
  "ShopDb::Schema::Result::PackingSlipLines",
  { "foreign.packing_slip_id" => "self.packing_slip_id" },
  { cascade_delete => 0, cascade_copy => 0 },
);

=head2 ship_address

Type: belongs_to

Related object: L<ShopDb::Schema::Result::Addresses>

=cut

__PACKAGE__->belongs_to(
  "ship_address",
  "ShopDb::Schema::Result::Addresses",
  { "foreign.address_id" => "self.ship_address_id" },
  { 'join_type' => 'left' },
);

sub update_quantity_shipped {
    my $self = shift;

    # Calculate total number shipped
    my $quantity_shipped = 0;
    for my $line ($self->lines) {
        $quantity_shipped += $line->quantity_shipped;
    }
    warn "Setting packing slip qty shipped to $quantity_shipped";
    $self->quantity_shipped($quantity_shipped);
    $self->update;
}

sub update {
    my $self = shift;
    my $next_method = $self->next::can;
    # Update job total quantity shipped
    $self->result_source->schema->txn_do(sub {
        $self->$next_method(@_);
        $self->job->update_quantity_shipped;
    });
    return $self;
}

sub audit_description {
    my $self = shift;
    return 'Packing Slip (' . $self->id . ')';
}

1;

