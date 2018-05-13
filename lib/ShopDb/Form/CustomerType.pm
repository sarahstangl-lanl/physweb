package ShopDb::Form::CustomerType;

use HTML::FormHandler::Moose;
extends 'ShopDb::Form::Base';

has '+item_class' => ( default => 'CustomerTypes' );

has_field 'customer_type_id' => (
    type => 'Hidden',
    auth => 0,
);

has_field 'label' => (
    auth => [ { item => [ 'new' ] }, { auth_args => [ 'foreman' ] } ],
    required => 1,
);

has_field 'sort_order' => (
    auth => [ { item => [ 'new' ] }, { auth_args => [ 'foreman' ] } ],
    required => 1,
);

has_field 'customer_type_add' => (
    type => 'Submit',
    value => 'Add Customer Type',
    inactive => 1,
    auth => 0,
);

has_field 'customer_type_update' => (
    type => 'Submit',
    value => 'Update Customer Type',
    inactive => 1,
    auth => 0,
);

no HTML::FormHandler::Moose;

1;
