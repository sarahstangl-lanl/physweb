package ShopDb::Schema::Result::JobEstimates;

use strict;
use warnings;

use base 'ShopDb::Schema::Base';

__PACKAGE__->table("shopdb.job_estimates");

=head1 ACCESSORS

=head2 job_estimate_id

=head2 job_id

=head2 creator_uid

=head2 date_created

=cut

__PACKAGE__->add_columns(
  "job_estimate_id",
  {
    data_type => "integer",
    default_value => undef,
    size => undef,
    is_auto_increment => 1,
  },
  "job_id",
  {
    data_type => "integer",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 0,
    size => undef,
  },
  "labor_rate",
  {
    data_type => "float",
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
  "edm_labor_rate",
  {
    data_type => "float",
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
  "creator_uid",
  {
    data_type => "integer",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 0,
    size => undef,
  },
  "created_date",
  {
    data_type => "date",
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
);
__PACKAGE__->set_primary_key("job_estimate_id");

=head1 RELATIONS

=head2 job

Type: belongs_to

Related object: L<ShopDb::Schema::Result::Jobs>

=cut

__PACKAGE__->belongs_to(
  "job",
  "ShopDb::Schema::Result::Jobs",
  { "foreign.job_id" => "self.job_id" },
);

=head2 creator

Type: belongs_to

Related object: L<ShopDb::Schema::Result::DirectoryEntry>

=cut

__PACKAGE__->belongs_to(
  "creator",
  "ShopDb::Schema::Result::DirectoryEntry",
  { "foreign.uid" => "self.creator_uid" },
);

=head2 labor_lines

Type: has_many

Related object: L<ShopDb::Schema::Result::LaborLines>

=cut

__PACKAGE__->has_many(
  "labor_lines",
  "ShopDb::Schema::Result::EstimateLaborLines",
  { "foreign.job_id" => "self.job_id" },
  { cascade_delete => 0, cascade_copy => 0 },
);

=head2 material_lines

Type: has_many

Related object: L<ShopDb::Schema::Result::EstimateMaterialLines>

=cut

__PACKAGE__->has_many(
  "material_lines",
  "ShopDb::Schema::Result::EstimateMaterialLines",
  { "foreign.job_id" => "self.job_id" },
  { cascade_delete => 0, cascade_copy => 0 },
);

sub insert {
    my $self = shift;

    my $result = $self->next::method(@_);

    # Create an audit entry for adding the estimate to a job
    $self->add_audit_entry({
        result_type => 'Jobs',
        result_id => $self->get_column('job_id'),
        action_type => 'relation',
        value => "Added Estimate '" . $self->audit_description . "'",
    });

    return $result;
}

sub delete {
    my $self = shift;

    # Create an audit entry for removing the estimate from a job
    $self->add_audit_entry({
        result_type => 'Jobs',
        result_id => $self->job_id,
        action_type => 'relation',
        value => "Removed Estimate '" . $self->audit_description . "'",
    });

    return $self->next::method(@_);
}

sub audit_description {
    my $self = shift;
    return $self->id;
}

1;
