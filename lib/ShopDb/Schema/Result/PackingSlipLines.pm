package ShopDb::Schema::Result::PackingSlipLines;

use strict;
use warnings;

use base 'ShopDb::Schema::Base';

=head1 NAME

ShopDb::Schema::Result::PackingSlipLines

=cut

__PACKAGE__->table("shopdb.packing_slip_lines");

=head1 ACCESSORS

=head2 packing_slip_line_id

=head2 packing_slip_id

=head2 description

=head2 quantity_backordered

=head2 quantity_shipped

=head2 is_comment

=cut

__PACKAGE__->add_columns(
  'packing_slip_line_id',
  {
    data_type => 'integer',
    default_value => undef,
    is_nullable => 0,
    is_auto_increment => 1,
  },
  'packing_slip_id',
  {
    data_type => 'integer',
    default_value => undef,
    is_nullable => 0,
    is_foreign_key => 1,
  },
  'description',
  {
    data_type => 'varchar',
    default_value => undef,
    is_nullable => 0,
    size => 1024,
  },
  'quantity_backordered',
  {
    data_type => 'integer',
    default_value => undef,
    is_nullable => 0,
  },
  'quantity_shipped',
  {
    data_type => 'integer',
    default_value => undef,
    is_nullable => 0,
  },
  'is_comment',
  {
    data_type => 'boolean',
    default_value => 0,
    is_nullable => 0,
  },
);
__PACKAGE__->set_primary_key('packing_slip_line_id');

=head1 RELATIONS

=head2 packing_slip

Type: belongs_to

Related object: L<ShopDb::Schema::Result::PackingSlips>

=cut

__PACKAGE__->belongs_to(
  "packing_slip",
  "ShopDb::Schema::Result::PackingSlips",
  { 'foreign.packing_slip_id' => 'self.packing_slip_id' },
);


sub insert {
    my $self = shift;
    my $return = $self->next::method(@_);
    $self->packing_slip->update_quantity_shipped;
    return $return;
}

sub update {
    my $self = shift;
    my $return = $self->next::method(@_);
    $self->packing_slip->update_quantity_shipped;
    return $return;
}

sub delete {
    my $self = shift;
    my $packing_slip = $self->packing_slip;
    my $return = $self->next::method(@_);
    $packing_slip->update_quantity_shipped;
    return $return;
}
sub audit_description {
    my $self = shift;
    return 'Packing Slip Line ' . $self->description . "(" . $self->id . ")";
}

1;

