#
# Tests some basic features specific to a Tablesearch::Data::DBI (DBI-backed) data source:
#  * dbh
#  * table
#  * where
#  * join

use Test::More 'no_plan';

use tablesearch;
use DBI;

my $dbh = DBI->connect('dbi:SQLite:db/book.db');
ok($dbh, 'get db handle');

my $ts = new Tablesearch(
	dbh => $dbh,
	table => 'address',
	where => ['address.country_iso = ?', 'GK'],
	joins => [
		'user' => ['user.user_id = address.user_id'],
	],
	no_calc_found_rows => 1,
);

my $dump = $ts->dump();

#
# Check that we got the three rows we expected (though in no particular order)
#
# We don't support having columns with the same name... so don't check those. If
# we wanted the data from those we would need to alias them to be different.
#

my %run_check;
my $i = 0;
for (my $i = 0; $i < 3; $i++) {
	my $address_id = $dump->{'data'}->[$i]->[0];
	
	if ($address_id == 1) {
		is($dump->{'data'}->[$i]->[2], '101 Main St');
		is($dump->{'data'}->[$i]->[5], 1);
		is($dump->{'data'}->[$i]->[6], 'jdoe');
		is($dump->{'data'}->[$i]->[11], '1970-04-23 21:06:00');
		
	} elsif ($address_id == 4) {
		is($dump->{'data'}->[$i]->[2], '142 Main St');
		is($dump->{'data'}->[$i]->[5], 2);
		is($dump->{'data'}->[$i]->[6], 'muffet');
		is($dump->{'data'}->[$i]->[11], '1983-10-24 22:22:22');
		
	} elsif ($address_id == 6) {
		is($dump->{'data'}->[$i]->[2], '991 Star St');
		is($dump->{'data'}->[$i]->[5], 3);
		is($dump->{'data'}->[$i]->[6], 'sam');
		is($dump->{'data'}->[$i]->[11], '1973-05-24 22:22:22');
	}
	
	$run_check{$address_id}++;
}

is($run_check{1}, 1);
is($run_check{4}, 1);
is($run_check{6}, 1);
