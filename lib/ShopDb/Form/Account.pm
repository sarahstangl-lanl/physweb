package ShopDb::Form::Account;

use HTML::FormHandler::Moose;
extends 'ShopDb::Form::Base';

use DateTime;

has '+item_class' => ( default => 'Accounts' );

has '+action' => ( default => 'account.html' );

has_field 'account_key' => (
    type => 'Hidden',
);

has_field 'descr50' => (
    type => 'Text',
    label => 'Description',
    size => 30,
    auth => [ { item => [ 'new' ] } ],
    required => 1,
);
has_field 'account_type' => (
    type => 'Select',
    auth => [ { item => [ 'new' ] }, { auth_args => [ 'foreman', 'accounting' ] } ],
    label_column => 'label',
    sort_column => 'sort_order',
    required => 1,
);
has_field 'setid' => (
    type => 'Hidden',
    default => 'UMFIN',
    auth => [ { item => [ 'new' ] } ],
    auth_over_foreman => 1,
);
has_field 'fund_code' => (
    type => 'Text',
    label => 'FUND',
    auth => [ { item => [ 'new' ] } ],
    auth_over_foreman => 1,
);
has_field 'deptid' => (
    type => 'Text',
    label => 'DEPTID',
    auth => [ { item => [ 'new' ] } ],
    auth_over_foreman => 1,
);
has_field 'program_code' => (
    type => 'Text',
    label => 'PRGM',
    auth => [ { item => [ 'new' ] } ],
    auth_over_foreman => 1,
);
has_field 'project_id' => (
    type => 'Text',
    label => 'PRJT',
    auth => [ { item => [ 'new' ] } ],
    auth_over_foreman => 1,
);
has_field 'chartfield1' => (
    type => 'Text',
    label => 'CF1',
    size => 10,
    auth => [ { item => [ 'new' ] } ],
    auth_over_foreman => 1,
);
has_field 'chartfield2' => (
    type => 'Text',
    label => 'CF2',
    size => 10,
    auth => [ { item => [ 'new' ] } ],
    auth_over_foreman => 1,
);
has_field 'chartfield3' => (
    type => 'Text',
    label => 'CF3/FINEE',
    size => 10,
    auth => [ { item => [ 'new' ] } ],
    auth_over_foreman => 1,
);
has_field 'disabled' => (
    type => 'Checkbox',
    label => 'Disabled',
    auth => [ { auth_args => [ 'foreman', 'accounting' ] } ],
);
has_field 'comment' => (
    type => 'Text',
    label => 'Comment',
    size => 30,
    auth => [ { item => [ 'new' ] }, { auth_args => [ 'foreman', 'accounting' ] } ],
);

has_field 'account_add' => (
    type => 'Submit',
    value => 'Add Account',
    inactive => 1,
);

has_field 'account_update' => (
    type => 'Submit',
    value => 'Update Account',
    inactive => 1,
);

sub validate {
    my $self = shift;
    my $key = join(';', map { $self->field($_)->value || '' } (qw/setid fund_code deptid program_code project_id chartfield3 chartfield1 chartfield2/));
    if (!$self->item && $self->schema->resultset('Accounts')->find({ account_key => $key })) {
        $self->add_form_error("The specified account already exists.");
    }
}

no HTML::FormHandler::Moose;
1;
