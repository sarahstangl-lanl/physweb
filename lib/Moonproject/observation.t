use Test::Simple tests => 1;
#!/usr/bin/perl

use strict;
use warnings;

use lib 'C:\Users\Shane\physweb\lib';
use lib '/home/admin/nick/git/physics/lib';
use lib '/home/admin/nick/git/sysadm/lib';

use Data::Dumper;

use Moonproject;
use Moonproject::Observation;

ok( $foo eq $bar, 'foo is bar' );