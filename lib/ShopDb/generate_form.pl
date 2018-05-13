#!/usr/local/bin/perl

use strict;
use lib '.';
use ShopDb::Schema;
use Getopt::Long;
use Pod::Usage;
use HTML::FormHandler::Generator::DBIC;

=head1 NAME

generate_form.pl - Generates a HTML-FormHandler form based on schema ResultSource

=head1 SYNOPSIS

form_generator.pl --rs_name=<ResultSource>

=cut

my $rs_name = '';
GetOptions('rs_name=s' => \$rs_name);
pod2usage(1) if !$rs_name;

my $mycnf = "/home/www/.my.cnf";
my $mycnfgroup = "webdb";
my $database = 'shopdb';
my $dsn = "DBI:mysql:database=$database;mysql_read_default_file=$mycnf;mysql_read_default_group=$mycnfgroup";
my $schema = ShopDb::Schema->connect($dsn, undef, undef);

my $generator = new HTML::FormHandler::Generator::DBIC(rs_name => $rs_name, schema => $schema);
print $generator->generate_form;
