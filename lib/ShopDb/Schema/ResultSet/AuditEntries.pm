package ShopDb::Schema::ResultSet::AuditEntries;

use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

sub with_directory_info {
    my ( $self ) = @_;

    return $self->search(
        {},
        {
            '+select' => [ \'CONCAT_WS(", ", directory.last_name, directory.first_name) AS display_name' ],
            '+as'     => [ 'display_name' ],
            join      => 'directory',
        }
    );
}

1;
