#!/usr/local/bin/perl

use strict;
use warnings;
use FindBin qw/$Bin/;

use lib "$Bin/..";

use Pod::Usage;
use Getopt::Long;
use Data::Dumper;
use SQL::Translator;

use ShopDb::Schema (qw/deploy/);

my ( $preversion, $help );
GetOptions(
'p|preversion:s'  => \$preversion,
) or die pod2usage;

my $mycnf = "/export/data/www/production/.my.cnf";
if (! -f $mycnf) {$mycnf = "/home/www/.my.cnf";}
my $mycnfgroup = "webdb";
my $database = 'shopdb';
my $dsn = "DBI:mysql:database=$database;mysql_read_default_file=$mycnf;mysql_read_default_group=$mycnfgroup";

my $schema = ShopDb::Schema->connect($dsn, undef, undef) || die "Failed to connect to database";

$schema->storage->sql_maker->quote_char('`');
$schema->storage->sql_maker->name_sep('.');
my $sql_dir = $schema->upgrade_directory || die "upgrade_directory not set for schema";
die "upgrade_directory $sql_dir does not exist" unless -d $sql_dir;
my $version = $schema->schema_version();
my $ddl_file = $schema->ddl_filename('MySQL', $version, $sql_dir);
my $diff_ddl_file = $schema->ddl_filename('MySQL', $version, $sql_dir, $preversion);
print "Creating DDL file $ddl_file for version $version" . ($preversion ? " and DDL diff file $diff_ddl_file for upgrading from version $preversion" : "") . "...\n";
$schema->create_ddl_dir( 'MySQL', $version, $sql_dir, $preversion, {
    add_drop_table => 0,
    producer_args => {
        mysql_version => '5.005009',
        quote_table_names => '`',
        quote_field_names => '`',
    },
    parser_args => {
        mysql_version => '5.005009',
        sources => [ grep { $schema->source($_)->name =~ /^shopdb\./; } $schema->sources ],
    },
} );
# Check DDL file for CASCADE settings
open(FILE, "<", $ddl_file) or die "Failed to open DDL file $ddl_file for reading: $!";
my $line = 1;
while(<FILE>) {
    if ($_ =~ /CASCADE/) {
        print STDERR "\nWARNING: Found CASCADE has_many relationship setting on line $line of $ddl_file:\n  ${_}Ensure \$attrs hashref for all has_many relationships includes 'cascade_delete => 0, cascade_copy => 0' and rerun this script. See http://zzz.physics.umn.edu/physnet/web/shopdb for more info.\n\n";
    }
    $line++;
}
print "Done\n";
