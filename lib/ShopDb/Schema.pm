package ShopDb::Schema;

use strict;
use warnings;
use base 'DBIx::Class::Schema';

our $VERSION = '0.44';

sub import {
    if (grep { /^deploy$/ } @_) {
        __PACKAGE__->load_components(qw/Schema::Versioned +ShopDb::Schema::Indices/);
        __PACKAGE__->upgrade_directory('/home/admin/nick/git/physics/lib/ShopDb/sql');
    }
    __PACKAGE__->load_namespaces;
}

sub BUILD {
    my $self = shift;
}

__PACKAGE__->mk_classdata('uid');

# These are used for JobStatuses customer_jobs and machinst_jobs relationships
__PACKAGE__->mk_classdata('customer_id');
__PACKAGE__->mk_classdata('machinist_id');

__PACKAGE__->mk_classdata('skip_audits');

1;
