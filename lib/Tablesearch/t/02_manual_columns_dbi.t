#
# Test manually specifying columns (as well as basic aliasing/AS support) for DBI
#

use Test::More 'no_plan';

use tablesearch;
use DBI;

my $dbh = DBI->connect('dbi:SQLite:db/book.db');
ok($dbh, 'get db handle');

my $ts = new Tablesearch(
	dbh => $dbh,
	table => 'employer',
	field_list => ['employer_id', 'category AS cat', 'country'],
	no_calc_found_rows => 1,
);

my $dump = $ts->dump();

is($dump->{'header'}->[0]->{'name'}, 'employer_id');
is($dump->{'header'}->[1]->{'name'}, 'cat');
is($dump->{'header'}->[2]->{'name'}, 'country');