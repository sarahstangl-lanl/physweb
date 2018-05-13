package ShopDb::Schema::ResultSet::Jobs;

use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

sub with_machinists {
    my ( $self ) = @_;

    return $self->search(
        {},
        {
            '+select' => [
                \'GROUP_CONCAT(machinist.shortname ORDER BY machinist.shortname SEPARATOR ", ") AS machinists',
                \'GROUP_CONCAT(machinist.machinist_id ORDER BY machinist.shortname) AS machinist_ids',
            ],
            '+as'     => [
                'machinists',
                'machinist_ids',
            ],
            join      => { 'job_assignments' => 'machinist' },
            group_by  => [ 'me.job_id' ],
        }
    );
}

sub with_parent_info {
    my $self = shift;
    return $self->search(
        {},
        {
            '+select'   => [ \'IFNULL(me.parent_job_id, me.job_id) AS job_id_sort_val', \'parent_job.project_name AS parent_name' ],
            '+as'       => [ 'job_id_sort_val', 'parent_name' ],
            join        => 'parent_job',
        },
    );
}

sub with_days_left {
    my ( $self ) = @_;

    return $self->search(
        {},
        {
            '+select' => (\'DATEDIFF(me.need_date, NOW()) AS days_left'),
            '+as'     => 'days_left',
        }
    );
}

sub with_directory_info {
    my ( $self ) = @_;

    return $self->search(
        {},
        {
            '+select' => [
                            \'CONCAT_WS(", ", directory.last_name, directory.first_name) AS customer_display_name',
                            \'CONCAT_WS(", ", directory_2.last_name, directory_2.first_name) AS pi_display_name',
                         ],
            '+as'     => [ 'customer_display_name', 'pi_display_name' ],
            join      => { 'customer' => 'directory', 'pi' => 'directory' },
        }
    );
}

sub with_status_info {
    my $self = shift;
    return $self->search(
        {},
        {
            '+select'   => [ qw/status.label/ ],
            '+as'       => [ qw/status/ ],
            join        => [ qw/status/ ],
        },
    );
}

1;
