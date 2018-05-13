#!/usr/local/bin/perl

use strict;
use warnings;
use Getopt::Long;
use Pod::Usage;
use FindBin qw/$Bin/;

use lib "$Bin/..";

use ShopDb::Schema (qw/deploy/);

=head1 NAME

schema_deploy.pl - Deploys ShopDB Schema

=head1 SYNOPSIS

schema_deploy.pl --sure | -s [--testdb | -t]

=cut

# Require -s or --sure to be passed to prevent accidental deployment
my $sure = '';
my $testdb = '';
GetOptions('sure' => \$sure, 'testdb' => \$testdb);
pod2usage(1) if !$sure;

my $mycnf = "/home/www/.my.cnf";
my $mycnfgroup = $testdb ? "webdb_test" : "webdb";
my $database = 'shopdb';
my $dsn = "DBI:mysql:database=$database;mysql_read_default_file=$mycnf;mysql_read_default_group=$mycnfgroup";

print "Attempting to connect using cnfgroup $mycnfgroup...\n";

my $schema = ShopDb::Schema->connect($dsn, undef, undef);
$schema->storage->debug(2);
$schema->storage->sql_maker->quote_char('`');
$schema->storage->sql_maker->name_sep('.');

# Determine if deploying from scratch or upgrading
my $schema_db_version = $schema->get_db_version();
if (!$schema_db_version) {
    # schema is unversioned
    print "No schema version found. Hit enter to deploy from scratch (Ctrl-C to cancel).\n";
    my $response = <STDIN>;
    # deploy ShopDB schema, skipping tables that don't begin with 'shopdb.'
    $schema->deploy({
        parser_args => {
            sources => [ grep { $schema->source($_)->name =~ /^shopdb\./; } $schema->sources ],
        },
    });
} else {
    # upgrade from generated DDL diff file
    print "Upgrading from schema version $schema_db_version. Hit enter to proceed (Ctrl-C to cancel).\n";
    my $response = <STDIN>;
    $schema->upgrade();
}
