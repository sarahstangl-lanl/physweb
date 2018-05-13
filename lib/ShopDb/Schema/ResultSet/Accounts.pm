package ShopDb::Schema::ResultSet::Accounts;

use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

sub with_project_info {
    my $self = shift;
    return $self->search({},
        {
            join => [ 'project' ],
            '+select' => [ \'`project`.`descr` AS `project_descr`' ],
            '+as' => [ 'project_descr' ],
        }
    );
}

sub with_account_type {
    my $self = shift;
    return $self->search({},
        {
            join => 'account_type',
            '+select' => [ \'`account_type`.`label` AS `account_type`' ],
            '+as' => [ 'account_type' ],
        }
    );
}

1;
