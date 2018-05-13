#!/usr/bin/perl

use strict;
use warnings;

use lib '.';

use DBI;
use Data::Dumper;
use ShopDb::Schema;
#use Lingua::EN::AddressParse;

my $dbh = DBI->connect("dbi:CSV:", undef, undef, {
    f_dir => "/tmp",
    f_ext => '.csv',
}) || die "Failed to connect: " . $DBI::errstr;

my $sth = $dbh->prepare("SELECT * FROM external_customers");
$sth->execute or die "Failed to execute: " . $sth->errstr;

my $mycnf = "/home/www/.my.cnf";
my $mycnfgroup = "webdb";
my $database = 'shopdb';
my $dsn = "DBI:mysql:database=$database;mysql_read_default_file=$mycnf;mysql_read_default_group=$mycnfgroup";

my $schema = ShopDb::Schema->connect($dsn, undef, undef);
$schema->uid(844);
$schema->skip_audits(1);
$schema->storage->sql_maker->quote_char('`');
$schema->storage->sql_maker->name_sep('.');
$schema->storage->debug(2);

my @customers = $schema->resultset('Customers')->search({ comments => { -like => '%@%' } }, {
        prefetch => 'directory',
    })->all;
for my $customer (@customers) {
    my $email = '';
    if ($customer->comments =~ /(\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}\b)/i) {
        $email = $1;
        my $last_name = $customer->directory->last_name;
        my $first_name = $customer->directory->first_name;
        unless ($email =~ m/$last_name/i || $email =~ /$first_name/i) {
            $email = '';
        }
    }
    printf "%50s | %50s | %50s\n", $customer->directory->display_name, $customer->comments, $email;
    if ($email) {
        my $directory = $schema->resultset('DirectoryEntry')->find($customer->directory_uid);
        next unless ($directory);
        $directory->email($email);
#        print Dumper({$directory->get_columns });
        $directory->update;
    }
}

#my $parser = Lingua::EN::AddressParse->new(country => 'US', auto_clean => 1);

#while (<>) {
#    my $row = $sth->fetchrow_hashref;
#    last unless ($row);
#    print "Company:\n  " . $row->{cust_name} . "\n";
my $i = 0;
my @failed_customers;
while (0 && $i++ < 1000 && (my $row = $sth->fetchrow_hashref)) {
    (my $billing_address = $row->{billing_address}) =~ s/(^[\r\n ]|[\r\n ]$)//gos;
    (my $shipping_address = $row->{shipping_address}) =~ s/(^[\r\n ]|[\r\n ]$)//gos;
    my $bill_address = $billing_address ? $schema->resultset('Addresses')->create({ company => $row->{cust_name}, lines => $billing_address }) : undef;
    my $ship_address = $shipping_address ? ($billing_address eq $shipping_address ? $bill_address : $schema->resultset('Addresses')->create({ company => $row->{cust_name}, lines => $shipping_address })) : undef;
    if ($row->{cust_contack}) {
        (my $customers = $row->{cust_contack}) =~ s/(^[\r\n ]|[\r\n ]$)//gos;
        my @customers = split(/[,\/&]/, $customers);
        for my $customer (@customers) {
            my ($title, $first_name, $last_name) = ($customer =~ /^\s{0,}([[:alpha:]]{2,}\.)?\s{0,}([[:alpha:] \'\-]+[^ ])\s+([[:alpha:]\'\-]+)\s{0,}$/);
            push(@failed_customers, $row->{id__}) && next if ($last_name && $last_name eq 'Geology');
            {
                no warnings 'uninitialized';
                if ($first_name =~ /^(Prof.*|Mme) /) {
                    $title = $1;
                    $first_name =~ s/^$1 //;
                }
#                printf "%50s | %30s | %10s | %20s | %20s\n", $customers, $customer, $title, $first_name, $last_name;
                if ($first_name && $last_name) {
                    (my $work_phone = $row->{cust_phone}) =~ s/(^[\r\n ]|[\r\n ]$)//gos;
                    (my $fax_number = $row->{cust_fax}) =~ s/(^[\r\n ]|[\r\n ]$)//gos;
                    (my $company_name = $row->{cust_name}) =~ s/(^[\r\n ]|[\r\n ]$)//gos;
                    (my $comments = $row->{misc}) =~ s/(^[\r\n ]|[\r\n ]$)//gos;
                    my $directory = $schema->resultset('DirectoryEntry')->create({ work_phone => $work_phone, last_name => $last_name, first_name => $first_name });
                    my $customer = $directory->create_related('customer', {
                            company_name => $company_name,
                            title => $title,
                            fax_number => $fax_number,
                            comments => $comments . (length($work_phone) > 40 ? (($comments ? " " : "") . $work_phone) : ""),
                            primary_ship_address => $ship_address ? $ship_address->id : undef,
                            primary_bill_address => $bill_address ? $bill_address->id : undef,
                    });
                    $customer->add_to_addresses($bill_address) if ($bill_address);
                    $customer->add_to_addresses($ship_address) unless (!$ship_address || ($bill_address && $bill_address->id eq $ship_address->id));
#                    print Dumper({
#                        directory => { $directory->get_columns },
#                        customer => { $customer->get_columns },
#                        ship_address => { $ship_address->get_columns },
#                        bill_address => { $bill_address->get_columns },
#                    });
                }
                else {
                    push(@failed_customers, $row->{id__});
                }
            }
        }
    }


#    for my $type (qw/shipping billing/) {
#        next unless ($row->{"${type}_address"});
#        my $address;
##        print ucfirst($type) . " address:\n";
#        my @parts = grep { /./ } split "\n", $row->{"${type}_address"};
#        next unless (@parts > 1);
#
#        print "  $_\n" for (@parts);
#        print "\n";
#
#        my $city_state_zip = pop @parts;
#        my $street = pop @parts;
#
#        $parser->parse(join(' ', $street, $city_state_zip));
#        my %properties = $parser->properties;
#        unless ($properties{type} eq 'unknown') {
#            my %components = $parser->components;
#            while (my ($key, $value) = each %components) {
#                next unless ($value);
#                print "  $key => $value\n";
#            }
#        }
#
#        if ($city_state_zip =~ /^\s*([^,]+)\s*,\s*([^ ]+)\s+([\d\-]+)\s*$/ ||
#            $city_state_zip =~ /^\s*([^,]+)\s+([A-Za-z]{2})\s+([\d\-]+)\s*$/) {
##                print "Found matching city, state, zip\n";
#            ($address->{city}, $address->{state}, $address->{zip}) = ($1, $2, $3);
#        }
#        if ($street =~ /\d/) {
#            $address->{street} = $street;
#        }
#        print "\n";
#        print "  street => " . $address->{street} . "\n" if ($address->{street});
#        print "  city   => " . $address->{city} . "\n" if ($address->{city});
#        print "  state  => " . $address->{state} . "\n" if ($address->{state});
#        print "  zip    => " . $address->{zip} . "\n" if ($address->{zip});
#        print "\n";
#    }
}
print join("\n", @failed_customers);
warn Dumper($sth->{NAME});
