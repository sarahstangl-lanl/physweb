package ShopDb::Schema::ResultSet::Machinists;

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

sub active {
    return (shift)->search({ 'me.active' => 1 });
}

sub exclude_admin {
    return (shift)->search({ 'me.shortname' => { -not_in => [ 'JAK', 'HAE', 'JS' ] }});
}

1;
