#
# Tests automatically determining columns (rather than user specified)
#

use Test::More 'no_plan';

use tablesearch;
use DBI;

my $dbh = DBI->connect('dbi:SQLite:db/book.db');
ok($dbh, 'get db handle');

my $ts = new Tablesearch(
	dbh => $dbh,
	table => 'employer',
	no_calc_found_rows => 1,
);

my $dump = $ts->dump();

is($dump->{'header'}->[0]->{'name'}, 'employer_id');
is($dump->{'header'}->[1]->{'name'}, 'name');
is($dump->{'header'}->[2]->{'name'}, 'category');
is($dump->{'header'}->[3]->{'name'}, 'country');
