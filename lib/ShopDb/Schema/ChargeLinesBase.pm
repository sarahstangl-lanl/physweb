package ShopDb::Schema::ChargeLinesBase;

use strict;
use warnings;

use base 'DBIx::Class::ResultSet';

sub active {
    return shift->search({ 'me.active' => 1 });
}

sub inactive {
    return shift->search({ 'me.active' => 0 });
}

sub with_directory_info {
    return shift->search({}, {
        '+select' => [ \'machinist.shortname AS machinist' ],
        '+as'     => [ 'machinist' ],
        join      => 'machinist',
#        '+select' => [ \'CONCAT_WS(", ", directory.last_name, directory.first_name) AS display_name', 'machinist.shortname', 'machinist.shortname' ],
#        '+as'     => [ 'display_name', 'shortname', 'machinist' ],
#        join      => { 'machinist' => 'directory' },
    });
}

sub with_billing_fields {
    return shift->search({}, {
        '+select'   => [
            \'\'\'',
            \'CONCAT(IF(`parent_job`.`job_id` IS NULL, \'\', CONCAT(`parent_job`.`project_name`, \': \')), `job`.`project_name`) AS full_project_name',
            \'CONCAT_WS(\', \', `directory`.`last_name`, `directory`.`first_name`) AS customer',
            \'account.descr50 AS efs_account',
            'customer.customer_id',
            'account.account_key',
        ],
        '+as'       => [ 'edit', 'project_name', 'customer', 'efs_account', 'customer_id', 'account_key' ],
        'join'  => { job => [ 'parent_job', 'account', { customer => 'directory' } ] },
    });
}

1;
