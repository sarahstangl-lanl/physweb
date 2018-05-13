package ShopDb::Schema::Result::Attachments;

use strict;
use warnings;

use base 'ShopDb::Schema::Base';

=head1 NAME

ShopDb::Schema::Result::Attachments

=cut

__PACKAGE__->table("shopdb.attachments");

=head1 ACCESSORS

=head2 attachment_id

=head2 filename

=head2 size

=head2 data

=head2 mime_type

=head2 upload_date

=head2 modified_date

=head2 uploader_uid

=cut

__PACKAGE__->add_columns(
  'attachment_id',
  {
    data_type => 'integer',
    default_value => undef,
    is_nullable => 0,
    is_auto_increment => 1,
  },
  'filename',
  {
    data_type => 'varchar',
    default_value => undef,
    is_nullable => 0,
    size => 255,
  },
  'size',
  {
    data_type => 'integer',
    default_value => undef,
    is_nullable => 0,
  },
  'data',
  {
    data_type => 'mediumblob',
    default_value => undef,
    is_nullable => 0,
  },
  'mime_type',
  {
    data_type => 'varchar',
    default_value => undef,
    is_nullable => 0,
    size => 255,
  },
  'upload_date',
  {
    data_type => 'datetime',
    is_nullable => 0,
  },
  'modified_date',
  {
    data_type => 'datetime',
    is_nullable => 0,
  },
  'uploader_uid',
  {
    data_type => 'integer',
    is_nullable => 0,
  },
);
__PACKAGE__->set_primary_key('attachment_id');

=head1 RELATIONS

=head2 uploader

Type: belongs_to

Related object: L<ShopDb::Schema::Result::Customers>

=cut

__PACKAGE__->belongs_to(
  "uploader",
  "ShopDb::Schema::Result::DirectoryEntry",
  { 'foreign.uid' => 'self.uploader_uid' },
);

=head2 job_attachments

Type: has_many

Related object: L<ShopDb::Schema::Result::JobAttachments>

=cut

__PACKAGE__->has_many(
  "job_attachments",
  "ShopDb::Schema::Result::JobAttachments",
  { 'foreign.attachment_id' => 'self.attachment_id' },
  { cascade_delete => 0, cascade_copy => 0 },
);

=head2 jobs

Type: many_to_many

Related object: L<ShopDb::Schema::Result::Jobs>

=cut

__PACKAGE__->many_to_many(
  "jobs",
  "job_attachments" => "job",
);

sub delete {
    my $self = shift;

    # Remove JobAttachments
    for my $job_attachment ($self->job_attachments) {
        $job_attachment->delete;
    }

    return $self->next::method;
}

sub update {
    my ($self, $updates) = @_;

    # Fetch original values for audit entry
    my $orig = $self->get_from_storage;

    # Update column values with passed-in args
    $self->set_columns($updates) if ($updates);

    my %changes = $self->get_dirty_columns;

    my $result = $self->next::method;

    # Create an audit entry for renaming the attachment
    if (exists $changes{'filename'}) {
        for my $job ($self->jobs) {
            $self->add_audit_entry({
                result_type => 'Jobs',
                result_id => $job->get_column('job_id'),
                action_type => 'update',
                value => "Renamed Attachment '" . $orig->audit_description . "' to '" . $self->audit_description . "'",
            });
        }
    }

    return $result;
}

sub audit_description {
    my $self = shift;
    $self->filename . ' (' . $self->id . ')';
}

1;
