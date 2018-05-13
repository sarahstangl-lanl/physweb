package ShopDb::Schema::Result::Jobs;

use strict;
use warnings;

use base 'ShopDb::Schema::Base';
use POSIX qw(strftime);

__PACKAGE__->table("shopdb.jobs");

=head1 ACCESSORS

=head2 job_id

=head2 customer_id

=head2 pi_id

=head2 project_name

=head2 instructions

=head2 date_in

=head2 customer_po_num

=cut

__PACKAGE__->add_columns(
  "job_id",
  {
    data_type => "integer",
    default_value => undef,
    size => undef,
    is_auto_increment => 1,
  },
  "filemaker_job_id",
  {
    data_type => "integer",
    default => undef,
    is_nullable => 1,
    size => undef,
  },
  "parent_job_id",
  {
    data_type => "integer",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 1,
    size => undef,
  },
  "job_status_id",
  {
    data_type => "integer",
    default => undef,
    is_nullable => 0,
    is_foreign_key => 1,
    size => undef,
  },
  "status_comment",
  {
    data_type => "varchar",
    default => undef,
    is_nullable => 1,
    size => 1024,
  },
  "customer_id",
  {
    data_type => "integer",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 1,
    size => undef,
  },
  "pi_id",
  {
    data_type => "integer",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 1,
    size => undef,
  },
  "property_id",
  {
    data_type => "varchar",
    default_value => undef,
    is_foreign_key => 0,
    is_nullable => 1,
    size => 255,
  },
  "account_key",
  {
    data_type => "varchar",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 1,
    size => 255,
  },
  "project_name",
  {
    data_type => "varchar",
    default_value => undef,
    is_nullable => 0,
    size => 255,
  },
  "instructions",
  {
    data_type => "varchar",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "justification",
  {
    data_type => "varchar",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "creation_date",
  {
    data_type => "date",
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
  "in_date",
  {
    data_type => "date",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "need_date",
  {
    data_type => "date",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "finish_date",
  {
    data_type => "date",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "ship_date",
  {
    data_type => "date",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "customer_po_num",
  {
    data_type => "varchar",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "customer_ref_1",
  {
    data_type => "varchar",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "customer_ref_2",
  {
    data_type => "varchar",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "contact_number",
  {
    data_type => "varchar",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "ship_address_id",
  {
    data_type => "integer",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 1,
    size => undef,
  },
  "bill_address_id",
  {
    data_type => "integer",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 1,
    size => undef,
  },
  "approved_date",
  {
    data_type => "date",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "ship_method",
  {
    data_type => "varchar",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "quantity_ordered",
  {
    data_type => "integer",
    default_value => 1,
    is_nullable => 0,
  },
  "quantity_shipped",
  {
    data_type => "integer",
    default_value => 0,
    is_nullable => 0,
  },
  "external",
  {
    data_type => "bool",
    default_value => 0,
    is_nullable => 0,
    size => undef,
  },
  "projected_charge_hours",
  {
    data_type => "integer",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "projected_labor_cost",
  {
    data_type => "integer",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "projected_material_cost",
  {
    data_type => "integer",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "entry_machinist_id",
  {
    data_type => "integer",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 1,
    size => undef,
  },
  "modified_date",
  {
    data_type => "datetime",
    default_value => undef,
    is_nullable => 0,
  },
);
__PACKAGE__->set_primary_key("job_id");

=head1 RELATIONS

=head2 status

Type: belongs_to

Related object: L<ShopDb::Schema::Result::JobStatuses>

=cut

__PACKAGE__->belongs_to(
  "status",
  "ShopDb::Schema::Result::JobStatuses",
  { "foreign.job_status_id" => "self.job_status_id" },
);

=head2 customer

Type: belongs_to

Related object: L<ShopDb::Schema::Result::Customers>

=cut

__PACKAGE__->belongs_to(
  "customer",
  "ShopDb::Schema::Result::Customers",
  { "foreign.customer_id" => "self.customer_id" },
  { 'join_type' => 'left', prefetch => [ 'directory' ] },
);

=head2 pi

Type: belongs_to

Related object: L<ShopDb::Schema::Result::Customers>

=cut

__PACKAGE__->belongs_to(
  "pi",
  "ShopDb::Schema::Result::Customers",
  { "foreign.customer_id" => "self.pi_id" },
  { 'join_type' => 'left', prefetch => [ 'directory' ] },
);

=head2 estimate

Type: might_have

Related object: L<ShopDb::Schema::Result::JobEstimates>

=cut

__PACKAGE__->might_have(
  "estimate",
  "ShopDb::Schema::Result::JobEstimates",
  { "foreign.job_id" => "self.job_id" },
  { "cascade_delete" => 0, "cascade_update" => 0 },
);

=head2 "account"

Type: belongs_to

Related object: L<ShopDb::Schema::Result::Accounts>

=cut

__PACKAGE__->belongs_to(
  "account",
  "ShopDb::Schema::Result::Accounts",
  { "foreign.account_key" => "self.account_key" },
  { 'join_type' => 'left' },
);

=head2 parent_job

Type: belongs_to

Related object: L<ShopDb::Schema::Result::Jobs>

=cut

__PACKAGE__->belongs_to(
  "parent_job",
  "ShopDb::Schema::Result::Jobs",
  { "foreign.job_id" => "self.parent_job_id" },
  { 'join_type' => 'left' },
);

=head2 child_jobs

Type: has_many

Related object: L<ShopDb::Schema::Result::Jobs>

=cut

__PACKAGE__->has_many(
  "child_jobs",
  "ShopDb::Schema::Result::Jobs",
  { "foreign.parent_job_id" => "self.job_id" },
  { cascade_delete => 0, cascade_copy => 0 },
);

=head2 labor_lines

Type: has_many

Related object: L<ShopDb::Schema::Result::LaborLines>

=cut

__PACKAGE__->has_many(
  "labor_lines",
  "ShopDb::Schema::Result::LaborLines",
  { "foreign.job_id" => "self.job_id" },
  { cascade_delete => 0, cascade_copy => 0 },
);

=head2 material_lines

Type: has_many

Related object: L<ShopDb::Schema::Result::MaterialLines>

=cut

__PACKAGE__->has_many(
  "material_lines",
  "ShopDb::Schema::Result::MaterialLines",
  { "foreign.job_id" => "self.job_id" },
  { cascade_delete => 0, cascade_copy => 0 },
);

=head2 machinists

Type: many_to_many

Related object: L<ShopDb::Schema::Result::Machinists>

=cut

__PACKAGE__->has_many(
  "job_assignments",
  "ShopDb::Schema::Result::JobAssignments",
  { "foreign.job_id" => "self.job_id" },
  { cascade_delete => 0, cascade_copy => 0, prefetch => { machinist => 'directory' } },
);

__PACKAGE__->many_to_many(
  "machinists",
  'job_assignments' => 'machinist',
);

=head2 attachments

Type: many_to_many

Related object: L<ShopDb::Schema::Result::Attachments>

=cut

__PACKAGE__->has_many(
  "job_attachments",
  "ShopDb::Schema::Result::JobAttachments",
  { "foreign.job_id" => "self.job_id" },
  { cascade_delete => 0, cascade_copy => 0, prefetch => [ 'attachment' ] },
);

__PACKAGE__->many_to_many(
  "attachments",
  'job_attachments' => 'attachment',
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

=head2 bill_address

Type: belongs_to

Related object: L<ShopDb::Schema::Result::Addresses>

=cut

__PACKAGE__->belongs_to(
  "bill_address",
  "ShopDb::Schema::Result::Addresses",
  { "foreign.address_id" => "self.bill_address_id" },
  { 'join_type' => 'left' },
);

=head2 entry_machinist_id

Type: belongs_to

Related object: L<ShopDb::Schema::Result::Machinists>

=cut

__PACKAGE__->belongs_to(
  "entry_machinist",
  "ShopDb::Schema::Result::Machinists",
  { "foreign.machinist_id" => "self.entry_machinist_id" },
  { 'join_type' => 'left' },
);

=head2 job_comments

Type: has_many

Related object: L<ShopDb::Schema::Result::JobComments>

=cut

__PACKAGE__->has_many(
  "job_comments",
  "ShopDb::Schema::Result::JobComments",
  { "foreign.job_id" => "self.job_id" },
  { cascade_delete => 0, cascade_copy => 0 },
);

=head2 invoices

Type: has_many

Related object: L<ShopDb::Schema::Result::Invoices>

=cut

__PACKAGE__->has_many(
  "invoices",
  "ShopDb::Schema::Result::Invoices",
  { "foreign.job_id" => "self.job_id" },
  { cascade_delete => 0, cascade_copy => 0 },
);

=head2 packing_slips

Type: has_many

Related object: L<ShopDb::Schema::Result::PackingSlips>

=cut

__PACKAGE__->has_many(
  "packing_slips",
  "ShopDb::Schema::Result::PackingSlips",
  { "foreign.job_id" => "self.job_id" },
  { cascade_delete => 0, cascade_copy => 0 },
);

=head2 job_summary

Type: belongs_to

Related object: L<ShopDb::Schema::Result::JobTotals>

=cut

__PACKAGE__->belongs_to(
  "job_summary",
  "ShopDb::Schema::Result::JobTotals",
  { "foreign.job_id" => "self.job_id" },
);

# Returns today in YYYY-MM-DD format
sub today {
    my @time = localtime();
    return strftime('%Y-%m-%d', @time);
}

sub new {
    my $class = shift;
    my $self = $class->next::method(@_);
    $self->creation_date($self->today) unless ($self->creation_date);
    return $self;
}

sub insert {
    my ($self, @args) = @_;
    my $next_method = $self->next::can;
    $self->result_source->schema->txn_do(sub {
        $self->$next_method(@args);
        $self->update_parent_machinists;
        $self->update_customer_accounts;
        $self->update_customer_addresses;
    });
    return $self;
}

sub update {
    my ($self, @args) = @_;
    my $next_method = $self->next::can;
    $self->result_source->schema->txn_do(sub {
        $self->$next_method(@args);
        $self->update_parent_machinists;
        $self->update_customer_accounts;
        $self->update_customer_addresses;
    });
    return $self;
}

sub update_parent_machinists {
    my $self = shift;
    if ($self->parent_job_id && (my $parent_job = $self->parent_job)) {
        warn "Updating parent job machinists";
        my @parent_machinists = $parent_job->machinists;
        for my $machinist ($self->machinists) {
            $parent_job->add_to_machinists($machinist)
                unless (grep { $_->id eq $machinist->id } @parent_machinists);
        }
    }
}

sub update_customer_accounts {
    my $self = shift;
    $self->customer->find_or_create_related('customer_accounts', { account_key => $self->account_key })
        if ($self->customer_id && $self->account_key);
    $self->pi->find_or_create_related('customer_accounts', { account_key => $self->account_key })
        if ($self->pi_id && $self->account_key);
}

sub update_customer_addresses {
    my $self = shift;
    warn "Updating customer addresses";
    # Add shipping and billing addresses to customer and pi
    for my $customer (qw/customer pi/) {
        warn "Processing $customer addresses";
        for my $address_id (qw/ship_address_id bill_address_id/) {
            warn "Processing address id $address_id";
            $self->$customer->find_or_create_related('customer_addresses', { address_id => $self->$address_id })
                if ($self->$customer && $self->$address_id);
        }
    }
}

sub update_quantity_shipped {
    my $self = shift;
    warn "Updating quantity_shipped";
    my $quantity_shipped = 0;
    for my $packing_slip ($self->packing_slips) {
        warn "Found packing slip " . $packing_slip->id . " with quantity " . $packing_slip->quantity_shipped;
        $quantity_shipped += $packing_slip->quantity_shipped
            if ($packing_slip->ship_date);
    }
    my %status_map = map { $_->label => $_->id } $self->result_source->schema->resultset('JobStatuses')->search->all;
    my %updates = ( quantity_shipped => $quantity_shipped );
    warn "Setting quantity shipped to $quantity_shipped";
    if ($quantity_shipped >= $self->quantity_ordered) {
        warn "Setting ship_date to today";
        $updates{ship_date} = $self->today;
        warn "Setting status to Shipped";
        $updates{job_status_id} = $status_map{'Shipped'};
    }
    elsif ($self->ship_date && $self->job_status_id == $status_map{'Shipped'}) {
        warn "Clearing ship_date";
        $updates{ship_date} = undef;
        warn "Setting status to Awaiting shipping";
        $updates{job_status_id} = $status_map{'Awaiting shipping'};
    }
    $self->update({ %updates });
}

sub approved {
    my ( $self ) = @_;
    return !(!$self->approved_date);
}

sub finalized {
    my ( $self ) = @_;
    return !(!$self->in_date);
}

sub audit_description {
    my $self = shift;
    return $self->project_name . ' (' . $self->id . ')';
}

1;
