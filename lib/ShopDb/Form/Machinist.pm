package ShopDb::Form::Machinist;

use HTML::FormHandler::Moose;
extends 'ShopDb::Form::Base';

has '+item_class' => ( default => 'Machinists' );

has_field 'directory_uid' => (
    type => '+CompletePeople',
    include_shop_customers => 1,
    label => 'Name',
    required => 1,
    required_message => 'You must specify a directory entry',
    apply => [ { check => sub { !(!$_[0]) }, message => 'You must specify a valid directory entry' } ],
    auth => [ { item => [ 'new' ] } ],
    auth_over_foreman => 1,
);

has_field 'labor_rate' => (
    required => 1,
    required_message => 'You must specify a labor rate',
);

has_field 'shortname' => (
    required => 1,
    required_message => 'You must specify a shortname',
);

has_field 'fulltime' => (
    label => 'Full-time',
    type => 'Checkbox',
);

has_field 'active' => (
    label => 'Active',
    type => 'Checkbox',
    default => 1,
);

has_field 'machinist_add' => (
    type => 'Submit',
    value => 'Add Machinist',
    inactive => 1,
);

has_field 'machinist_update' => (
    type => 'Submit',
    value => 'Update Machinist',
    inactive => 1,
);

no HTML::FormHandler::Moose;
1;
