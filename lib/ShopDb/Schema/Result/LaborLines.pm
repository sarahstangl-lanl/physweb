package ShopDb::Schema::Result::LaborLines;

use strict;
use warnings;

use base 'ShopDb::Schema::Base';


=head1 NAME

ShopDb::Schema::Result::LaborLines

=cut

__PACKAGE__->table('shopdb.labor_lines');

=head1 ACCESSORS

=head2 labor_line_id

=head2 job_id

=head2 description

=head2 charge_date

=head2 charge_hours

=head2 machinist_id

=head2 invoice_id

=head2 bill_date

=head2 paid_date

=head2 finalized

=head2 active

=cut

__PACKAGE__->add_columns(
  'labor_line_id',
  {
    data_type => 'integer',
    default_value => undef,
    is_nullable => 0,
    size => undef,
    is_auto_increment => 1,
  },
  'job_id',
  {
    data_type => 'integer',
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 0,
    size => undef,
  },
  'description',
  {
    data_type => 'varchar',
    default_value => undef,
    is_nullable => 0,
    size => 255,
  },
  'charge_date',
  {
    data_type => 'date',
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
  'charge_hours',
  {
    data_type => 'float',
    default_value => 0,
    is_nullable => 0,
    size => undef,
  },
  'machinist_id',
  {
    data_type => 'integer',
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 0,
    size => undef,
  },
  'invoice_id',
  {
    data_type => 'varchar',
    default_value => undef,
    is_nullable => 1,
    size => 30,
  },
  'bill_date',
  {
    data_type => 'date',
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  'paid_date',
  {
    data_type => 'date',
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  'finalized',
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
  },
);
__PACKAGE__->set_primary_key('labor_line_id');

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

=head2 invoice

Type: belongs_to

Related object: L<ShopDb::Schema::Result::Invoices>

=cut

__PACKAGE__->belongs_to(
  'invoice',
  'ShopDb::Schema::Result::Invoices',
  { 'foreign.invoice_id' => 'self.invoice_id' },
);

=head2 machinist

Type: belongs_to

Related object: L<ShopDb::Schema::Result::Machinists>

=cut

__PACKAGE__->belongs_to(
  'machinist',
  'ShopDb::Schema::Result::Machinists',
  { 'foreign.machinist_id' => 'self.machinist_id' },
);

sub insert {
    my $self = shift;

    my $result = $self->next::method(@_);

    # Create an audit entry for adding the line to a job
    $self->add_audit_entry({
        result_type => 'Jobs',
        result_id => $self->get_column('job_id'),
        action_type => 'relation',
        value => "Added Labor Line '" . $self->audit_description . "'",
    });

    return $result;
}

sub update {
    my ($self, $updates) = @_;

    # Store old job info for audit entries
    my $old_line = $self->get_from_storage;
    my $old_job_descr = $old_line->job->audit_description;
    my $old_job_id = $old_line->get_column('job_id');
    warn "old_job_id $old_job_id";

    # Update column values with passed-in args
    $self->set_columns($updates) if ($updates);

    # Store changes for checking whether the line is moving between jobs
    my %changes = $self->get_dirty_columns;

    my $result = $self->next::method;

    # Create audit entries for moving the line to a different job
    if (exists $changes{'job_id'}) {
        my %attrs = (
            result_type => 'Jobs',
            action_type => 'relation',
            value => "Moved Labor Line '" . $self->audit_description . "' from Job '" . $old_job_descr . "' to '" . $self->job->audit_description . "'",
        );
        $self->add_audit_entry({
            result_id => $self->get_column('job_id'),
            %attrs,
        });
        $self->add_audit_entry({
            result_id => $old_job_id,
            %attrs,
        });
    }

    # Create an audit entry for marking the line (in)active
    if (exists $changes{'active'}) {
        $self->add_audit_entry({
            result_type => 'Jobs',
            result_id => $self->get_column('job_id'),
            action_type => 'relation',
            value => "Marked Labor Line '" . $self->audit_description . "' " . ($self->active ? 'active' : 'inactive'),
        });
    }

    return $result;
}

sub delete {
    die "Labor lines can not be deleted";
}

sub audit_description {
    my $self = shift;
    return $self->get_column('description') . ' (' . $self->id . ')';
}

1;
