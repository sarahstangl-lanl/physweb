#!/usr/bin/perl

use strict;
use warnings;

use ShopDb::GenerateInvoice;

my $invoice = ShopDb::GenerateInvoice->new(
    form_type => 'INVOICE',
    customer_address => "123 Main St\nNowhere, MN 55123",
    form_lines => [
        'Brass material|1|$23.00|$23.00',
        'Brass material|1|$23.00|$23.00',
    ],
);
$invoice->generate;

