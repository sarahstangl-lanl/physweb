package ShopDb::Form::Address;

use HTML::FormHandler::Moose;
extends 'ShopDb::Form::Base';

has '+item_class' => ( default => 'Addresses' );

has_field 'address_id' => (
    type => 'Hidden',
    auth => 0,
);

has_field 'company' => (
    style => 'width:300px',
    required => 1,
);
has_field 'lines' => (
    type => 'TextArea',
    rows => '5',
    style => 'width:300px',
    required => 1,
);
has_field 'address_add' => (
    type => 'Submit',
    value => 'Add Address',
    inactive => 1,
);
has_field 'address_update' => (
    type => 'Submit',
    value => 'Update Address',
    inactive => 1,
);

no HTML::FormHandler::Moose;
1;
