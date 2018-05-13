package ShopDb::Schema::Result::EstimateLaborLines;

use strict;
use warnings;

use base 'ShopDb::Schema::Base';


=head1 NAME

ShopDb::Schema::Result::EstimateLaborLines

=cut

__PACKAGE__->table('shopdb.estimate_labor_lines');

=head1 ACCESSORS

=head2 estimate_labor_line_id

=head2 job_estimate_id

=head2 category

=head2 category_value

=head2 description

=head2 charge_hours

=cut

__PACKAGE__->add_columns(
  'estimate_labor_line_id',
  {
    data_type => 'integer',
    default_value => undef,
    is_nullable => 0,
    size => undef,
    is_auto_increment => 1,
  },
  'job_estimate_id',
  {
    data_type => 'integer',
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 0,
    size => undef,
  },
  'category',
  {
    data_type => 'varchar',
    default_value => undef,
    is_nullable => 0,
    size => 255,
  },
  'category_value',
  {
    data_type => 'varchar',
    default_value => undef,
    is_nullable => 0,
    size => 255,
  },
  'description',
  {
    data_type => 'varchar',
    default_value => undef,
    is_nullable => 0,
    size => 255,
  },
  'charge_hours',
  {
    data_type => 'float',
    default_value => 0,
    is_nullable => 0,
    size => undef,
  },
);
__PACKAGE__->set_primary_key('estimate_labor_line_id');

=head1 RELATIONS

=head2 job_estimate

Type: belongs_to

Related object: L<ShopDb::Schema::Result::JobEstimates>

=cut

__PACKAGE__->belongs_to(
  'job_estimate',
  'ShopDb::Schema::Result::JobEstimates',
  { 'foreign.job_estimate_id' => 'self.job_estimate_id' },
);

sub insert {
    my $self = shift;

    my $result = $self->next::method(@_);

    # Create an audit entry for adding the line to a job
    $self->add_audit_entry({
        result_type => 'JobEstimates',
        result_id => $self->get_column('job_estimate_id'),
        action_type => 'relation',
        value => "Added Labor Line '" . $self->audit_description . "'",
    });

    return $result;
}

sub delete {
    my $self = shift;

    my $result = $self->next::method(@_);

    # Create an audit entry for removing the line from a job
    $self->add_audit_entry({
        result_type => 'JobEstimates',
        result_id => $self->get_column('job_estimate_id'),
        action_type => 'relation',
        value => "Deleted Labor Line '" . $self->audit_description . "'",
    });

    return $result;
}

sub audit_description {
    my $self = shift;
    return $self->get_column('description') . ' (' . $self->id . ')';
}

1;
