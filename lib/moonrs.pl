#!/usr/bin/perl

use strict;
use warnings;

use lib '/home/admin/nick/git/physics/lib';
use Data::Dumper;
use DateTime;
use DateTime::Duration;
use DateTime::Format::Strptime;
use Astro::Coord::ECI;
use Astro::Coord::ECI::Moon;
use Astro::Coord::ECI::Utils qw{deg2rad};

my $lat = deg2rad (44.58);    # Radians
my $long = deg2rad (-93.16);  # Radians
my $alt = 259 / 1000;        # Kilometers
my $sta = Astro::Coord::ECI->new(refraction => 1)->geodetic($lat, $long, $alt);
my $hour_dur = DateTime::Duration->new(hours => 1);
my $sec_dur = DateTime::Duration->new(seconds => 30);
my $dt = DateTime->new(year => 2012, month => $ARGV[0], day => $ARGV[1], hour => 6, time_zone => '-0600');
use POSIX (qw/floor/);
my $day = floor($dt->epoch/60/60/24);
print "day: $day\n";
my $moon = Astro::Coord::ECI::Moon->new(station => $sta)->universal($dt->epoch);
my @alm = $moon->almanac_hash;
my $rise = undef;
my $set = undef;
for (@alm) {
    next unless ($_->{almanac}->{event} eq 'horizon');
    my $event_dt = DateTime->from_epoch(time_zone => '-0600', epoch => $_->{time});
    if ($event_dt->is_dst) {
        $event_dt->subtract_duration($hour_dur);
    }
    if ($event_dt->sec > 0) {
        $event_dt->add_duration($sec_dur);
    }
    my $time = $event_dt->strftime("%H%M");
    if ($_->{almanac}->{detail} == 0) {
        $set = $time;
    }
    elsif ($_->{almanac}->{detail} == 1) {
        $rise = $time;
    }
}
print "rise: $rise, set: $set\n";
