package ShopDb::Schema::Result::JobComments;

use strict;
use warnings;

use base 'ShopDb::Schema::Base';

__PACKAGE__->table("shopdb.job_comments");

=head1 ACCESSORS

=head2 job_comment_id

=head2 text

=head2 job_id

=head2 creator_uid

=head2 customer_visible

=head2 include_on_invoice

=cut

__PACKAGE__->add_columns(
  "job_comment_id",
  {
    audit_description => 'Job Comment ID',
    data_type => "integer",
    default_value => undef,
    size => undef,
    is_auto_increment => 1,
  },
  "comment",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
  "job_id",
  {
    data_type => "integer",
    default_value => undef,
    is_foreign_key => 1,
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
  "customer_visible",
  {
    data_type => "boolean",
    default_value => 0,
    is_nullable => 0,
    size => undef,
  },
  "include_on_invoice",
  {
    data_type => "boolean",
    default_value => 0,
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
__PACKAGE__->set_primary_key("job_comment_id");

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

sub insert {
    my $self = shift;

    my $result = $self->next::method(@_);

    # Create an audit entry for adding the comment to a job
    $self->add_audit_entry({
        result_type => 'Jobs',
        result_id => $self->get_column('job_id'),
        action_type => 'relation',
        value => "Added Comment '" . $self->audit_description . "'",
    });

    return $result;
}

sub update {
    my ($self, $updates) = @_;

    # Store old comment info for audit entries
    my $old_comment = $self->get_from_storage->audit_description;

    # Update column values with passed-in args
    $self->set_columns($updates) if ($updates);

    # Store changes for checking whether the line is moving between jobs
    my %changes = $self->get_dirty_columns;

    my $result = $self->next::method;

    $self->add_audit_entry({
        result_id => $self->job_id,
        result_type => 'Jobs',
        action_type => 'relation',
        value => "Changed Comment from '" . $old_comment . "' to '" . $self->audit_description . "'",
    });

    return $result;
}

sub delete {
    my $self = shift;

    # Create an audit entry for removing the comment from a job
    $self->add_audit_entry({
        result_type => 'Jobs',
        result_id => $self->job_id,
        action_type => 'relation',
        value => "Removed Comment '" . $self->audit_description . "'",
    });

    return $self->next::method(@_);
}

sub audit_description {
    my $self = shift;
    return $self->comment;
}

1;
