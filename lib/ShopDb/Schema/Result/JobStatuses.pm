package ShopDb::Schema::Result::JobStatuses;

use strict;
use warnings;

use base 'ShopDb::Schema::Base';

__PACKAGE__->table("shopdb.job_statuses");

=head1 ACCESSORS

=head2 job_status_id

=head2 label

=cut

__PACKAGE__->add_columns(
  "job_status_id",
  {
    data_type => "integer",
    default_value => undef,
    size => undef,
    is_auto_increment => 1,
  },
  "label",
  {
    data_type => "varchar",
    default_value => undef,
    size => 255,
    is_nullable => 0,
  },
  "sort_order",
  {
    data_type => "integer",
    default_value => undef,
    size => undef,
    is_nullable => 0,
  },
);
__PACKAGE__->set_primary_key("job_status_id");

=head1 RELATIONS

=head2 jobs

Type: has_many

Related object: L<ShopDb::Schema::Result::Jobs>

=cut

__PACKAGE__->has_many(
  "jobs",
  "ShopDb::Schema::Result::Jobs",
  { 'foreign.job_status_id' => 'self.job_status_id' },
  { cascade_delete => 0, cascade_copy => 0 },
);

=head2 customer_jobs

Type: has_many

Related object: L<ShopDb::Schema::Result::Jobs>

=cut

__PACKAGE__->has_many(
  "customer_jobs",
  "ShopDb::Schema::Result::Jobs",
  sub {
    my $args = shift;
    my $schema = $args->{self_resultsource}->schema;
    my $customer_id = $schema->customer_id;
    warn "Got customer_id: $customer_id";
    return {
      "$args->{foreign_alias}.job_status_id" => { -ident => "$args->{self_alias}.job_status_id" },
      -or => [
        "$args->{foreign_alias}.customer_id" => $customer_id,
        "$args->{foreign_alias}.pi_id" => $customer_id,
      ],
    };
  },
  { cascade_delete => 0, cascade_copy => 0 },
);

=head2 machinist_jobs

Type: has_many

Related object: L<ShopDb::Schema::Result::Jobs>

=cut

__PACKAGE__->has_many(
  "machinist_jobs",
  "ShopDb::Schema::Result::Jobs",
  sub {
    my $args = shift;
    my $schema = $args->{self_resultsource}->schema;
    my $machinist_id = $schema->machinist_id;
    warn "Got machinist_id: $machinist_id";
    return {
      "$args->{foreign_alias}.job_status_id" => { -ident => "$args->{self_alias}.job_status_id" },
      -or => [
        "$args->{foreign_alias}.entry_machinist_id" => $machinist_id,
        "$args->{foreign_alias}.job_id" => { -in => \['SELECT `job_id` FROM `shopdb`.`job_assignments` WHERE `machinist_id` = ?', [ dummy => $machinist_id ] ] },
      ],
    };
  },
  { cascade_delete => 0, cascade_copy => 0 },
);

sub audit_description {
    my $self = shift;
    return $self->label;
}

1;
