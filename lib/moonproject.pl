#!/usr/bin/perl

use strict;
use warnings;

use lib '/home/admin/nick/git/physics/lib';
use lib '/home/admin/nick/git/sysadm/lib';

use Data::Dumper;
use physdb;
use Moonproject;
use Moonproject::Observation;
use Moonproject::Student;
use Moonproject::TA;

$Moonproject::term = 'spring';
$Moonproject::year = 2013;

physdb::connect(undef, "/home/www/.my.cnf", "webdb");

my $obs = Moonproject::Observation->new( student => 1347, term => "spring", year => 2013 )->load( number => 1, type => "last" );
warn Dumper($obs);

#my $student = Moonproject::Student->new( gradesid => 2 );
my $student = $obs->student;
warn Dumper($student);

my $ta = $student->ta;
warn Dumper($ta);
