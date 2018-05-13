package ShopDb::Schema::ResultSet::Addresses;

use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

sub with_relationships {
    my ( $self ) = @_;

    return $self->search(
        {},
        {
            '+select' => [ \'GROUP_CONCAT(DISTINCT CONCAT(directory.last_name, ", ", directory.first_name) SEPARATOR "<br/>") AS customers', \'GROUP_CONCAT(DISTINCT jobs.job_id SEPARATOR "<br/>") AS jobs', \'GROUP_CONCAT(DISTINCT packing_slips.packing_slip_id SEPARATOR "<br/>") AS packing_slips' ],
            '+as'     => [ qw/customers jobs packing_slips/ ],
            join      => [ { customer_addresses => { 'customer' => 'directory' } }, qw/jobs packing_slips/ ],
            group_by => 'me.address_id',
        }
    );
}

1;

