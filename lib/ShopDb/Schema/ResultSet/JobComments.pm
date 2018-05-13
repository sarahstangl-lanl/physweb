package ShopDb::Schema::ResultSet::JobComments;

use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

sub with_creator_info {
    return shift->search({}, {
        '+select'   => \"CONCAT_WS(', ', `creator`.`last_name`, `creator`.`first_name`)",
        '+as'       => 'creator',
        'join'      => [ 'creator' ],
    });
}

1;
