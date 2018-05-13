package ShopDb::Schema::Indices;

use strict;
use warnings;

sub sqlt_deploy_hook {
    my ($self, $sqlt_schema) = @_;

    my $indices = {
            'shopdb.jobs' => [ { name => 'external', fields => [ 'external' ] } ],
            'shopdb.attachments' => [ { name => 'uploader_uid', fields => [ 'uploader_uid' ] } ],
            'shopdb.shopdb_settings' => [ { name => 'name', fields => [ 'name' ] } ],
            'shopdb.audit_entries' => [ { name => 'result_type_id', fields => [ qw/result_type result_id/ ] },
                                        { name => 'entry_date', fields => [ qw/entry_date/ ] } ],
            'shopdb.accounts' => [
                { name => 'setid', fields => [ qw/setid/ ] },
                { name => 'fund_code', fields => [ qw/fund_code/ ] },
                { name => 'deptid', fields => [ qw/deptid/ ] },
                { name => 'program_code', fields => [ qw/program_code/ ] },
                { name => 'project_id', fields => [ qw/project_id/ ] },
                { name => 'chartfield3', fields => [ qw/chartfield3/ ] },
                { name => 'chartfield1', fields => [ qw/chartfield1/ ] },
                { name => 'chartfield2', fields => [ qw/chartfield2/ ] },
            ],
    };

    while (my ($table, $index_list) = each %$indices) {
        for my $index (@$index_list) {
            $sqlt_schema->get_table($table)->add_index(name => $index->{name}, fields => $index->{fields});
        }
    }
}

1;
