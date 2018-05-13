package ShopDb::Form::Invoice;

use HTML::FormHandler::Moose;
extends 'ShopDb::Form::Base';

has '+item_class' => ( default => 'Invoices' );

no HTML::FormHandler::Moose;
1;
