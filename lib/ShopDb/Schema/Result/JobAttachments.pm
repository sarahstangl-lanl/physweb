package ShopDb::Schema::Result::JobAttachments;

use strict;
use warnings;

use base 'ShopDb::Schema::Base';


=head1 NAME

ShopDb::Schema::Result::JobAttachments

=cut

__PACKAGE__->table("shopdb.job_attachments");

=head1 ACCESSORS

=head2 job_attachment_id

=head2 job_id

=head2 attachment_id

=cut

__PACKAGE__->add_columns(
  "job_attachment_id",
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
  "attachment_id",
  {
    data_type => "integer",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 0,
    size => undef,
  },
);
__PACKAGE__->set_primary_key('job_attachment_id');
__PACKAGE__->add_unique_constraint([ 'job_id', 'attachment_id' ]);

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

=head2 attachment

Type: belongs_to

Related object: L<ShopDb::Schema::Result::Attachments>

=cut

__PACKAGE__->belongs_to(
  'attachment',
  'ShopDb::Schema::Result::Attachments',
  { 'foreign.attachment_id' => 'self.attachment_id' },
);

sub insert {
    my $self = shift;

    my $result = $self->next::method(@_);

    # Create an audit entry for adding the attachment to a job
    $self->add_audit_entry({
        result_type => 'Jobs',
        result_id => $self->get_column('job_id'),
        action_type => 'relation',
        value => "Added Attachment '" . $self->audit_description . "'",
    });

    return $result;
}

sub delete {
    my $self = shift;

    # Store job info for audit entry
    my $job_id = $self->get_column('job_id');

    my $result = $self->next::method;

    # Create audit entry for removing the attachment from a job
    $self->add_audit_entry({
        result_type => 'Jobs',
        result_id => $job_id,
        action_type => 'relation',
        value => "Removed Attachment '" . $self->audit_description . "'",
    });

    return $result;
}

sub audit_description {
    my $self = shift;
    my $from_rel = shift;
    return $self->attachment->audit_description;
}

1;
