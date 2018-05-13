#
# Tests sorting when aliasing (DBI) is used. This ensures, for example, that the aliased
# names are recognized as correct names (otherwise it will reset to default, thinking
# they are invalid).
#

use Test::More 'no_plan';

use tablesearch;
use DBI;

my $dbh = DBI->connect('dbi:SQLite:db/book.db');
ok($dbh, 'get db handle');

my $ts = new Tablesearch(
	dbh => $dbh,
	table => 'book',
	where => ['length IS NOT NULL'],
	field_list => ['isbn', 'title AS book', 'pages AS length', 'year AS whenats'],
	default_sort_field => 'book',
	default_sort_dir => 'asc',
	no_calc_found_rows => 1,
);

$ts->import_request_args({
	sort => 'length',
	sort_reverse => 0,
});

my $dump = $ts->dump();

isa_ok($dump, 'HASH');
isa_ok($dump->{'data'}, 'ARRAY');
isa_ok($dump->{'header'}, 'ARRAY');

is($dump->{'data'}->[0]->[1], 'Perl Testing: A Developer\'s Notebook');
is($dump->{'data'}->[1]->[1], 'Idioten');
is($dump->{'data'}->[4]->[1], 'Harry Potter and the Order of the Phoenix');

$ts = new Tablesearch(
	dbh => $dbh,
	table => 'book',
	where => ['length IS NOT NULL'],
	field_list => ['isbn', 'title AS book', 'pages AS length', 'year AS whenats'],
	default_sort_field => 'book',
	default_sort_dir => 'desc',
	no_calc_found_rows => 1,
);

$ts->import_request_args({
	sort => 'length',
	sort_reverse => 1, # reverses the default of desc specified above
});

$dump = $ts->dump();

isa_ok($dump, 'HASH');
isa_ok($dump->{'data'}, 'ARRAY');
isa_ok($dump->{'header'}, 'ARRAY');

is($dump->{'data'}->[0]->[1], 'Harry Potter and the Order of the Phoenix');
is($dump->{'data'}->[3]->[1], 'Idioten');
is($dump->{'data'}->[4]->[1], 'Perl Testing: A Developer\'s Notebook');
