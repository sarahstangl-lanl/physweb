#!/usr/local/bin/perl

use strict;
use ShopDb::Schema;
use DBI;
use Data::Dumper;

my $mycnf = "/export/data/www/production/.my.cnf";
if (! -f $mycnf) {$mycnf = "/home/www/.my.cnf";}
my $mycnfgroup = "webdb";
my $database = 'shopdb';
my $dsn = "DBI:mysql:database=$database;mysql_read_default_file=$mycnf;mysql_read_default_group=$mycnfgroup";

my $dbh = DBI->connect($dsn, undef, undef) or die "Failed to connect to database";
