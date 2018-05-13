#
# Tests column header formatting options
#

use Test::More 'no_plan';

use tablesearch;
use DBI;

my $dbh = DBI->connect('dbi:SQLite:db/book.db');
ok($dbh, 'get db handle');

# WARNING. These custom formatting subs are not suitable
# for HTML use as they fail to escape their output.
# (The named ones will escape when using html output, however.)

my $ts = new Tablesearch(
	dbh => $dbh,
	table => 'country',
	where => ['iso = ?', 'US'],
	header_format => sub { my ($text) = @_; return 'xx' . $text . 'xx'; },
	data_format => 'lc',
	field_params => {
		'iso' => { header_format => 'uc' },
		'name' => { header_format => 'ucfirst' },
		'printable_name' => {
			header_format => 'ucfirst_all',
			data_format => sub { my ($text) = @_; $text = uc($text); $text =~ s/ /_/g; return $text; },
		},
	},
	no_calc_found_rows => 1,
);

my $dump = $ts->dump();

isa_ok($dump, 'HASH');
isa_ok($dump->{'data'}, 'ARRAY');
isa_ok($dump->{'header'}, 'ARRAY');

is($dump->{'header'}->[0]->{'display_name'}, 'ISO');
is($dump->{'header'}->[1]->{'display_name'}, 'Name');
is($dump->{'header'}->[2]->{'display_name'}, 'Printable Name');
is($dump->{'header'}->[3]->{'display_name'}, 'xxiso3xx');

is($dump->{'data'}->[0]->[0], 'us');
is($dump->{'data'}->[0]->[1], 'united states');
is($dump->{'data'}->[0]->[2], 'UNITED_STATES');
