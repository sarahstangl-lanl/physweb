package ShopDb::Schema::Result::JobAssignments;

use strict;
use warnings;

use base 'ShopDb::Schema::Base';


=head1 NAME

ShopDb::Schema::Result::JobAssignments

=cut

__PACKAGE__->table("shopdb.job_assignments");

=head1 ACCESSORS

=head2 job_assignment_id

=head2 job_id

=head2 machinist_id

=cut

__PACKAGE__->add_columns(
  "job_assignment_id",
  {
    data_type => "integer",
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
  "machinist_id",
  {
    data_type => "integer",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 0,
    size => undef,
  },
);
__PACKAGE__->set_primary_key('job_assignment_id');
__PACKAGE__->add_unique_constraint([ 'job_id', 'machinist_id' ]);

=head1 RELATIONS

=head2 job

Type: belongs_to

Related object: L<ShopDb::Schema::Result::Jobs>

=cut

__PACKAGE__->belongs_to(
  'job',
  'ShopDb::Schema::Result::Jobs',
  { 'foreign.job_id' => 'self.job_id' },
);

=head2 machinist

Type: belongs_to

Related object: L<ShopDb::Schema::Result::Machinists>

=cut

__PACKAGE__->belongs_to(
  'machinist',
  'ShopDb::Schema::Result::Machinists',
  { 'foreign.machinist_id' => 'self.machinist_id' },
  { prefetch => 'directory' },
);

sub insert {
    my $self = shift;

    my $result = $self->next::method(@_);

    # Create an audit entry for adding the machinst to a job
    $self->add_audit_entry({
        result_type => 'Jobs',
        result_id => $self->get_column('job_id'),
        action_type => 'relation',
        value => "Added Machinist '" . $self->audit_description . "'",
    });

    return $result;
}

sub delete {
    my $self = shift;

    # Store job info for audit entry
    my $job_id = $self->get_column('job_id');

    my $result = $self->next::method;

    # Create audit entry for removing the machinist from a job
    $self->add_audit_entry({
        result_type => 'Jobs',
        result_id => $job_id,
        action_type => 'relation',
        value => "Removed Machinist '" . $self->audit_description . "'",
    });

    return $result;
}

sub audit_description {
    my $self = shift;
    my $from_rel = shift;
    return $self->machinist->audit_description;
}

1;
