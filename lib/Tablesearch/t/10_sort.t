#
# Tests table sorting functions
#

use Test::More 'no_plan';

use tablesearch;
use DBI;

my $dbh = DBI->connect('dbi:SQLite:db/book.db');
ok($dbh, 'get db handle');

my $ts = new Tablesearch(
	dbh => $dbh,
	table => 'book',
	default_sort_field => 'id',
	default_sort_dir => 'asc',
	no_calc_found_rows => 1,
);

my $dump = $ts->dump();

isa_ok($dump, 'HASH');
isa_ok($dump->{'data'}, 'ARRAY');
isa_ok($dump->{'header'}, 'ARRAY');

is($dump->{'data'}->[0]->[3], 'J.K. Rowling');
is($dump->{'data'}->[1]->[2], 'Idioten');
is($dump->{'data'}->[4]->[2], 'Winnie The Pooh');

$ts = new Tablesearch(
	dbh => $dbh,
	table => 'book',
	default_sort_field => 'id',
	default_sort_dir => 'asc',
	no_calc_found_rows => 1,
);

# Note: under mason request args are automatically imported. See 50_mason.t
$ts->import_request_args({
	sort => 'title',
	sort_reverse => 1, # reverses the default of asc specified above
});

$dump = $ts->dump();

is($dump->{'data'}->[0]->[2], 'Winnie The Pooh');
is($dump->{'data'}->[4]->[2], 'Idioten');
is($dump->{'data'}->[5]->[3], 'J.K. Rowling');
