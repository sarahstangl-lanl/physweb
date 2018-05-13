package ShopDb::Form::PackingSlipLine;

use HTML::FormHandler::Moose;
extends 'ShopDb::Form::Base';

has '+item_class' => ( default => 'PackingSlipLines' );

has_field 'packing_slip_id' => (
    required => 1,
    widget => 'NoRender',
);
has_field 'description' => (
    required => 1,
);
has_field 'quantity_backordered' => (
    required => 1,
    type => 'Integer',
);
has_field 'quantity_shipped' => (
    required => 1,
    type => 'Integer',
);
has_field 'is_comment' => (
    type => 'Boolean',
    widget => 'Hidden',
    default => 0,
);
has_field 'comment_add' => (
    type => 'Submit',
    value => 'Add Packing Slip Comment',
    inactive => 1,
);
has_field 'comment_update' => (
    type => 'Submit',
    value => 'Update Packing Slip Comment',
    inactive => 1,
);
has_field 'line_add' => (
    type => 'Submit',
    value => 'Add Packing Slip Line',
    inactive => 1,
);
has_field 'line_update' => (
    type => 'Submit',
    value => 'Update Packing Slip Line',
    inactive => 1,
);

no HTML::FormHandler::Moose;
1;
