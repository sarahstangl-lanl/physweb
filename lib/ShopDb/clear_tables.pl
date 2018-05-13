#!/usr/bin/perl

unshift(@INC, '.');
use strict;
use Pod::Usage;
use ShopDb::Schema (qw/deploy/);
use Getopt::Long;
use Data::Dumper;
use DBI;

# Require -s or --sure to be passed to prevent accidental empties
my $sure = '';
GetOptions('sure' => \$sure);
pod2usage(1) if !$sure;

my $mycnf = "/export/data/www/production/.my.cnf";
if (! -f $mycnf) {$mycnf = "/home/www/.my.cnf";}
my $mycnfgroup = "webdb";
my $database = 'shopdb';
my $dsn = "DBI:mysql:database=$database;mysql_read_default_file=$mycnf;mysql_read_default_group=$mycnfgroup";
my $dbh = DBI->connect($dsn, undef, undef) or die "Failed to connect to database";
my $schema = ShopDb::Schema->connect($dsn, undef, undef) || die "Failed to connect to database";
$schema->storage->sql_maker->quote_char('`');
$schema->storage->sql_maker->name_sep('.');

# Drop shopdb database
$dbh->do("SET foreign_key_checks=0");
$dbh->do("DROP DATABASE `shopdb`");
$dbh->do("SET foreign_key_checks=1");

my $delete_entry = $dbh->prepare("DELETE FROM `webdb`.`directory` WHERE `webdb`.`directory`.`uid` = ? LIMIT 1");
my $delete_memberships = $dbh->prepare("DELETE FROM `webdb`.`groupmembers` WHERE `webdb`.`groupmembers`.`uid` = ?");

# Get shopdb customers from directory
my @uids;
my $sth = $dbh->prepare("SELECT uid FROM `webdb`.`groupmembers` WHERE `webdb`.`groupmembers`.`groupname` = ?");
$sth->execute("shopdb");
while(my $row = $sth->fetchrow_hashref) {
    push(@uids, $row->{'uid'});
}

# Delete memberships/entries
for (@uids) {
    print "Deleting memberships for uid $_\n";
    $delete_memberships->execute($_) or die "Failed to delete memberships for uid " . $_ . ": " . $delete_entry->errstr;
    print "Deleted " . $delete_memberships->rows . " rows\n";
    print "Deleting entry for uid $_\n";
    $delete_entry->execute($_) or die "Failed to delete entry for uid " . $_ . ": " . $delete_entry->errstr;
    print "Deleted " . $delete_entry->rows . " rows\n";
}

# Create shopdb database
$dbh->do("CREATE DATABASE `shopdb`");

# Determine if deploying from scratch or upgrading
my $schema_db_version = $schema->get_db_version();
if (!$schema_db_version) {
    # schema is unversioned
    print "No schema version found. Attempting to deploy from scratch...\n";
    # deploy ShopDB schema, skipping tables that don't begin with 'shopdb.'
    $schema->deploy({
        parser_args => {
            sources => [ grep { $schema->source($_)->name =~ /^shopdb\./; } $schema->sources ],
        },
    });
} else {
    # upgrade from generated DDL diff file
    $schema->upgrade();
}

# Add job_entry_uid setting
$dbh->do("INSERT INTO `shopdb`.`shopdb_settings` (`name`, `value`, `is_unique`) VALUES ('job_entry_uid', 7621, 1)");

# Add machinists
$dbh->do("INSERT INTO `shopdb`.`machinists` (`machinist_id`, `directory_uid`, `labor_rate`, `shortname`, `fulltime`, `active`) VALUES
(1, 7, 100, 'RWB', 1, 1),
(11, 1308, 100, 'CKC', 1, 1),
(21, 1046, 100, 'PNN', 1, 1),
(31, 23, 80, 'GOD', 0, 1),
(41, 6951, 80, 'NGW', 0, 1),
(51, 81, 100, 'AK', 1, 1),
(61, 194, 100, 'GLH', 1, 1),
(71, 80, 100, 'JAK', 1, 1)");

# Add job statuses
$dbh->do("INSERT INTO `shopdb`.`job_statuses` (`label`) VALUES
    ('Draft'),
    ('Awaiting approval'),
    ('Awaiting assignment'),
    ('In progress'),
    ('Hold material'),
    ('Hold changes'),
    ('Finished'),
    ('Awaiting shipping'),
    ('Shipped'),
    ('Cancelled')");

