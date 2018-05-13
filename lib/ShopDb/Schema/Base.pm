package ShopDb::Schema::Base;

use strict;
use warnings;

use base 'DBIx::Class::Core';

use Data::Dumper;

sub insert {
    my $self = shift;

    return $self->next::method(@_) if ($self->result_source->schema->skip_audits);

    warn "Inserting " . $self->result_source->source_name;

    # Fetch filtered column values
    my %values = %{ $self->filter_audit_values({ $self->get_columns }) };

    my $result = $self->next::method(@_);

    # Don't create audit entry for creating audit entries!
    return $result if ($self->result_source->source_name eq 'AuditEntries');

    # Update schema directory_uid and session uid if none set and creating a new directory entry
    if ($self->result_source->source_name eq 'DirectoryEntry') {
        $self->result_source->schema->uid($self->uid)
            unless ($self->result_source->schema->uid);
        $HTML::Mason::Commands::session{'uid'} = $self->uid
            unless ($HTML::Mason::Commands::session{'uid'});
    }

    # Create audit log entry
    $self->add_audit_entry({
        action_type     => 'insert',
        value           => 'Created entry and set ' . join(', ', map { "'$_' to '" . $self->audit_value($values{$_}) . "'" } keys %values),
    });

    return $result;
}

sub delete {
    my $self = shift;

    return $self->next::method(@_) if ($self->result_source->schema->skip_audits);

    # Fetch filtered column values
    my %values = %{ $self->filter_audit_values({ $self->get_columns }) };

    my $result = $self->next::method(@_);

    # Create audit log entry
    $self->add_audit_entry({
        action_type     => 'delete',
        value           => 'Deleted entry with values ' . join(', ', map { "'$_' => '" . $self->audit_value($values{$_}) . "'" } keys %values),
    });

    return $result;
}

sub update {
    my ($self, $updates) = @_;

    return $self->next::method($updates) if ($self->result_source->schema->skip_audits);

    warn "Updating " . $self->result_source->source_name;

    # Update column values with passed-in args
    $self->set_columns($updates) if ($updates);

    # Fetch original row for storing original value in audit log
    my $orig = $self->get_from_storage;

    # Fetch filtered changed columns
    my %changes = %{ $self->filter_audit_values({ $self->get_dirty_columns }) };

    my $result = $self->next::method;

    # Create audit log entry
    $self->add_audit_entry({
        action_type     => 'update',
        value           => 'Changed ' . join(', ', map { "'$_' from '" . $self->audit_value($orig->get_column($_)) . "' to '" . $self->audit_value($changes{$_}) . "'" } keys %changes),
    }) if (%changes);

    return $result;
}

# Allow filtering audit entry columns by result source name
sub filter_audit_values {
    my ($self, $values) = @_;
    my $column_filters = {
        'Attachments' => [ qw/modified_date upload_date data/ ],
        'DirectoryEntry' => [ qw/modified_date create_date/ ],
        'Jobs' => [ qw/modified_date/ ],
    };
    if (exists $column_filters->{$self->result_source->source_name}) {
        delete $values->{$_} for (@{ $column_filters->{$self->result_source->source_name} });
    }
    return $values;
}

# Format value for audit entries
sub audit_value {
    my ($self, $value) = @_;
    if (ref $value eq 'SCALAR') {
        $value = $$value;
    }
    elsif (ref $value) {
        warn "Unknown audit value ref " . (ref $value);
        warn Dumper($value);
    }
    return defined $value ? $value : 'NULL';
}

sub add_audit_entry {
    my $self = shift;
    my $attrs = shift;
    $self->result_source->schema->resultset('AuditEntries')->create({
        directory_uid   => $self->result_source->schema->uid,
        result_type     => $self->result_source->source_name,
        result_id       => join(',', $self->id),
        %$attrs,
    });
}

sub audit_entries {
    my ($self, %args) = @_;
    my @ids = [ $self->id ];
    my (@extra_select, @extra_as);
    if ($args{'with_child_jobs'}) {
        push @ids, $self->child_jobs->get_column('job_id')->all;
        push @extra_select, 'result_id';
        push @extra_as, 'result_id';
    }
    return $self->result_source->schema->resultset('AuditEntries')->search(
        {
            result_type => $self->result_source->source_name,
            result_id => \@ids,
        },
        {
            join        => [ 'directory' ],
            group_by    => [qw/value entry_date/],
            'select'    => [
                { max => 'entry_id', -as => 'entry_id' },
                'result_type',
                'action_type',
                'value',
                'entry_date',
                \'CONCAT(directory.last_name, ", ", directory.first_name) AS display_name',
                @extra_select,
            ],
            'as'        => [
                'entry_id',
                'result_type',
                'action_type',
                'value',
                'entry_date',
                'display_name',
                @extra_as,
            ],
            order_by    => 'entry_date'
        }
    );
}

1;
