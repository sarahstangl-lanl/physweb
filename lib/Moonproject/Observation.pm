package Moonproject::Observation;

use strict;
use warnings;

use Data::Dumper;
use DateTime;
use DateTime::Duration;
use DateTime::Format::MySQL;

use Math::Trig;

use Astro::Coord::ECI;
use Astro::Coord::ECI::Moon;
use Astro::Coord::ECI::Utils;
use Moonproject;
use Moonproject::Student;
use physdb;



my $moon_info_cache = {};






use constant PI => atan2 (0, -1);



sub new {
    my $class = shift;
    my $self = { @_ };
    $self->{grades} = [ qw/SUB OBS CST DAY PHN AVE MHF MHD SHC EHA EDT UP/ ];
    $self->{columns} = [ qw/id number date cstTime phaseNumber fists fists2 fists3 aveFist moonHA cloud dayNumber sunHA elongation studentComments taComments student timestamp gradeSUB gradeOBS gradeCST gradeDAY gradePHN gradeAVE gradeMHF gradeMHD gradeSHC gradeEHA gradeEDT gradeUP realCST taAccepted realAVE realMHF realMHD realSHC realDAY realEHA realEDT realPHN term year tolObsToSubmitDiff tolObsToLastDiff tolCST tolDayNumber tolAverageFists tolMoonHAFists tolMoonHADate tolMoonHADatePercent tolSunHACST tolElongHA tolElongDate tolPhaseNumber ta_uid fist_degrees current/ ];
    bless $self, $class;
    if (ref $self->{student}) {
        $self->{student_obj} = $self->{student};
        $self->{student} = $self->{student_obj}->{gradesid};
    }
    if ($self->{id}) {
        $self->load(id => $self->{id});
    }
    else {
        die "id or student are required" unless ($self->{student});
    }
    return $self;
}

sub load {
    my $self = shift;
    my $args = { @_ };
    my $obs;
    if ($args->{id}) {
        $obs = physdb::queryfirstrow("SELECT * FROM moonproject.observation WHERE id = ?", $args->{id});
    }
    elsif ($args->{number}) {
        die "student is required to load by number" unless ($self->{student});
        $self->{term} ||= $args->{term} || $Moonproject::term;
        $self->{year} ||= $args->{year} || $Moonproject::year;
        die '$Moonproject::term and $Moonproject::year must be set if term and year are not provided'
            unless (($self->{term} && $self->{year}) || ($Moonproject::term && $Moonproject::year));
        my $func = 'MAX'; # default to last
        $func = 'MIN' if ($args->{type} && $args->{type} eq 'first');
#        physdb::dbh->trace(2);
        $obs = physdb::queryfirstrow("SELECT * FROM moonproject.observation WHERE id = (SELECT $func(id) FROM moonproject.observation WHERE student = ? AND number = ? AND term = ? AND year = ? GROUP BY number)", $self->{student}, $args->{number}, $self->{term}, $self->{year});
#        physdb::dbh->trace(0);
    }
    else {
        die "load requires id or number";
    }
    if ($obs) {
        $self->{loaded} = 1;
        for my $col (@{$self->{columns}}) {
            $self->{$col} = $obs->{$col};
        }
        if ($self->{student_obj} && $self->{student_obj}->{gradesid} != $self->{student}) {
            delete $self->{student_obj};
        }
    }
    return $self;
}

sub student {
    my $self = shift;
    return $self->{student_obj} if ($self->{student_obj});
    die "student not set" unless ($self->{student});
    $self->{student_obj} = Moonproject::Student->new(gradesid => $self->{student});
}

sub ta {
    my $self = shift;
    return $self->{ta_obj} if ($self->{ta_obj});
    $self->{ta_obj} = Moonproject::TA->new(uid => $self->{ta_uid});
}

sub precommit {
    my $self = shift;
    # Store fist_degrees with record
    $self->{fist_degrees} = $self->student->{fistdegrees};
    # Store TA tolerances with record
    $self->{$_} = $self->student->ta->{$_} for (grep { $_ =~ /^tol/ } keys %{ $self->student->ta });
    $self->{ta_uid} = $self->student->ta->{uid};
    # Replace empty strings with undef
    $self->{$_} = (defined $self->{$_} && $self->{$_} eq '') ? undef : $self->{$_} for (@{ $self->{columns} });
    # Set defaults
    $self->{taAccepted} = 'unset' unless (defined $self->{taAccepted});
}

sub commit {
    my $self = shift;
    $self->precommit;
    # Mark current
    $self->{current} = 1;
    # Mark old records not current
    physdb::query('UPDATE moonproject.observation SET current = 0 WHERE student = ? AND term = ? AND year = ? AND number = ?', $self->{student}, $self->{term}, $self->{year}, $self->{number});
    # Insert record
    physdb::query('INSERT INTO moonproject.observation (' . join(',', @{ $self->{columns} }) . ') VALUES (' . join(',', map { '?' } @{ $self->{columns} }) . ')', map { $self->{$_} } @{ $self->{columns} });
    return $self;
}

sub regrade {
    my $self = shift;
    unless ($self->{dt}) {
        $self->{dt} = DateTime::Format::MySQL->parse_datetime($self->{date})->set_time_zone('America/Chicago');
    }
    $self->calculate_grades;
    $self->precommit;
    # Update record
    physdb::query(
        'UPDATE moonproject.observation SET ' . join(', ', map { "$_ = ?" } @{ $self->{columns} }) . ' WHERE id = ? LIMIT 1',
        map { $self->{$_} } @{ $self->{columns} }, 'id',
    );
    return $self;
}

sub attempts {
    my $self = shift;
    physdb::queryone("SELECT COUNT(*) FROM moonproject.observation WHERE student = ? AND number = ? AND term = ? AND year = ?", $self->{student}, $self->{number}, $self->{term}, $self->{year});
}

sub ta_tolerance_check {
    my $self = shift;
    my $student = $self->student;
    my $ta = $self->ta;
    my $student_ta = $student->ta;
    return "This observation was graded with default tolerance values." unless ($self->{ta_uid});
    return "This observation was graded with " . $ta->{name} . "'s tolerances." unless ($ta->{uid} == $student->{ta_uid});
    for my $col (grep { $_ =~ /^tol/ } @{ $self->{columns} }) {
        return 'This observation was graded with a different ' . $col . ' value.' unless ($self->{$col} == $student_ta->{$col});
    }
    return 0;
}

sub calculate_values {
    my $self = shift;
    $self->{realCST} = $self->compute_CST($self->{dt});
    $self->{realDAY} = ($self->{dt}->day_of_year);
    $self->{realPHN} = $self->compute_elongation_from_date($self->{dt}) / 45;
    $self->{realMHF} = $self->compute_moonHA_from_fists($self->{aveFist}, $self->student->{fistdegrees});
    $self->{realMHD} = $self->getAZI($self->{dt}); #this is actually the azimuthal angle
    $self->{realSHC} = $self->compute_sunHA_from_CST($self->{cstTime});
    $self->{realEHA} = $self->{sunHA} ne '' ? $self->compute_elongation_from_HA($self->{sunHA}, $self->{moonHA}) : undef;
    $self->{realEDT} = $self->getNewElongation($self->{dt});
    $self->{realAVE} = $self->compute_average_from_fists($self->{fists}, $self->{fists2}, $self->{fists3});
    $self->{test} = $self->grade_mhd;
    # print "Hello World";
    return $self;
}

sub calculate_grades {
    my $self = shift;
    for my $grade (@{ $self->{grades} }) {
        my $grade_method = "grade_" . lc ($grade);
        $self->{"grade$grade"} = $self->$grade_method;
    }
    return $self;
}


sub get_tolerance {
    my $self = shift;
    my $tolerance = shift;
    die "Unknown tolerance $tolerance" unless (exists $self->student->ta->{$tolerance});
    return $self->student->ta->{$tolerance};
}

sub get_station {
    my $self = shift;
    my $date = shift;
    die "First argument to get_station must be a DateTime object" unless (ref $date eq 'DateTime');
    # Coordinates and elevation for Minneapolis, MN as per http://aa.usno.navy.mil/data/docs/RS_OneYear.php and http://www.gpsvisualizer.com/elevation
    my $lat = Astro::Coord::ECI::Utils::deg2rad(44.9778); #deg2rad (44.58);    # Radians #  Error during compilation of /home/www/docs/staging/4445/www/resources/moonproject/autohandler: Prototype mismatch: sub Moonproject::Observation::deg2rad ($;$) vs none at /usr/local/lib/perl5/5.16/Exporter.pm line 66, <DATA> line 129.

    my $long = Astro::Coord::ECI::Utils::deg2rad (-93.2650);  # Radians
    my $alt = 259 / 1000;         # Kilometers
    return Astro::Coord::ECI->geodetic($lat, $long, $alt)->universal($date->epoch);
}
sub get_next_elevation {
    my $self = shift;
    my $date = shift;
    $date = $self->get_cst_dt_from_epoch($date)
        unless (ref $date);
    my $station = $self->get_station($date);
    my $moon = Astro::Coord::ECI::Moon->new(station => $station);
    # Get next rise/set event
    my ($time, $rise) = $station->next_elevation($moon);
    warn "g et_next_elevation($date): time = " . $self->get_cst_dt_from_epoch($time) . ", rise: $rise";
    return ($time, $rise);
}
sub get_last_elevation {
    my $self = shift;
    my $date = shift;
    $date = $self->get_cst_dt_from_epoch($date)
        unless (ref $date);
    warn "get_last_elevation($date)";
    my $station = $self->get_station($date);
    my $moon = Astro::Coord::ECI::Moon->new(station => $station);
    my $day = $date->clone->truncate(to => 'day');
    my $elevation;
    do {
        warn $day;
        my @almanac = $moon->almanac($day->epoch);
        for my $event (@almanac) {
            warn Dumper($event);
            next unless ($event->[1] eq 'horizon');
            $elevation = $event if ($event->[0] < $date->epoch);
        }
        $day->subtract_duration(DateTime::Duration->new(days => 1));
    } while (!$elevation);
    warn "get_last_elevation($date): time = " . $self->get_cst_dt_from_epoch($elevation->[0]) . ', rise: ' . $elevation->[2];
    return ($elevation->[0], $elevation->[2]);
}
sub get_cst_dt_from_epoch {
    my $self = shift;
    my $epoch = shift;
    my $dt = DateTime->from_epoch(epoch => $epoch, time_zone => '-0600');
    warn "epoch: $epoch, dt: $dt";
    return $dt;
}
sub get_moon_info {
    my $self = shift;
    my $date = shift;
    die "First argument to get_moon_info must be a DateTime object" unless (ref $date eq 'DateTime');
    warn "get_moon_info: dt = $date, epoch = " . $date->epoch;
    if (exists $moon_info_cache->{$date->epoch}) {
        warn "Returning cached moon info";
        return $moon_info_cache->{$date->epoch};
    }
    my $moon_info;
    # Get moon rise/set info
    my ($time, $rise) = $self->get_next_elevation($date);
    # If next event is moon rise, moon wasn't up during time
    if ($rise) {
        # Check if within 30 minutes before rise
        if ($date->epoch + 60*30 >= $time) {
            $moon_info->{rise_time} = $self->get_cst_dt_from_epoch($time);
            ($time, undef) = $self->get_next_elevation($time);
            $moon_info->{set_time} = $self->get_cst_dt_from_epoch($time);
        }
        else {
            # Check if within 30 minutes after set
            my ($set_time, undef) = $self->get_last_elevation($time);
            if ($set_time + 60*30 >= $date->epoch) {
                warn "Date within 30 minutes after set, using interval";
                $moon_info->{set_time} = $self->get_cst_dt_from_epoch($set_time);
                my ($rise_time, undef) = $self->get_last_elevation($set_time);
                $moon_info->{rise_time} = $self->get_cst_dt_from_epoch($rise_time);
            }
            else {
                warn "Moon was down during $date";
                $moon_info_cache->{$date->epoch} = undef;
                return undef;
            }
        }
    }
    else {
        $moon_info->{set_time} = $self->get_cst_dt_from_epoch($time);
        ($time, undef) = $self->get_last_elevation($time);
        $moon_info->{rise_time} = $self->get_cst_dt_from_epoch($time);
    }
    $moon_info->{midpoint} = $self->get_cst_dt_from_epoch(($moon_info->{rise_time}->epoch + $moon_info->{set_time}->epoch)/2);
    $moon_info_cache->{$date->epoch} = $moon_info;
    return $moon_info;
}
# Check if the observation date is within given tolerance of original submission date
sub grade_sub {
    my $self = shift;
    my $tolObsToSubmitDiff = $self->get_tolerance('tolObsToSubmitDiff');
    # Get original submission date (default to now if new observation)
    my $orig_submission = Moonproject::Observation->new( student => $self->{student} )->load( number => $self->{number}, type => 'first' );
    my $timestamp = $orig_submission->{loaded} ? DateTime::Format::MySQL->parse_timestamp($orig_submission->{timestamp})->epoch : time;
    # Check if submission date is within tolObsToSubmitDiff seconds of observation date
    return 'fail' if ($timestamp - $self->{dt}->epoch > $tolObsToSubmitDiff);
    return 'pass';
}
# Check if submission date is at least given hours from other observations
sub grade_obs {
    my $self = shift;
    my ($last_observation, $next_observation) = $self->get_adjoining_observations;
    my $tolObsToLastDiff = $self->get_tolerance('tolObsToLastDiff');
    my ($last_dt, $next_dt);
    $last_dt = DateTime::Format::MySQL->parse_datetime($last_observation->{date})->set_time_zone('America/Chicago') if ($last_observation);
    $next_dt = DateTime::Format::MySQL->parse_datetime($next_observation->{date})->set_time_zone('America/Chicago') if ($next_observation);
    return 'fail' if ($last_observation && $self->{dt}->epoch - $tolObsToLastDiff < $last_dt->epoch);
    return 'fail' if ($next_observation && $self->{dt}->epoch + $tolObsToLastDiff > $next_dt->epoch);
    return 'pass';
}
# Check if CST is within given tolerance
sub grade_cst {
    my $self = shift;
    my $tolCST = $self->get_tolerance('tolCST');
    return 'fail' unless (abs($self->{cstTime}-$self->{realCST}) <= $tolCST);
    return 'pass';
}
# Check if dayNumber matches calculated value
sub grade_day {
    my $self = shift;
    my $tolDayNumber = $self->get_tolerance('tolDayNumber');
    return 'unknown' unless ($self->{dayNumber} ne '');
    return 'fail' unless ($self->{dayNumber} == $self->{realDAY});
    return 'pass';
}
# Check if chosen phase sketch and phase number are within given tolerance
sub grade_phn {
    my $self = shift;
    my $tolPhaseNumber = $self->get_tolerance('tolPhaseNumber');
    warn 'phn';
    warn Dumper({
            tolPhaseNumber => $tolPhaseNumber,
            phaseNumber => $self->{phaseNumber},
            realPHN => $self->{realPHN},
            'abs(phaseNumber - realPHN)' => (abs($self->{phaseNumber} - $self->{realPHN})),
            'abs(abs(phaseNumber - realPHN) - 8)' => (abs(abs($self->{phaseNumber} - $self->{realPHN}) - 8)),
     
    });
    return 'fail' unless ((abs($self->{phaseNumber} - $self->{realPHN}) < $tolPhaseNumber || abs(abs($self->{phaseNumber} - $self->{realPHN}) - 8) < $tolPhaseNumber));
    return 'pass';
}
sub grade_mhf {
    my $self = shift;
    my $tolMoonHAFists = $self->get_tolerance('tolMoonHAFists');
    return 'unknown' unless ($self->{moonHA} ne '');
    return 'fail' unless (abs($self->{moonHA} - $self->{realMHF}) <= $tolMoonHAFists);
    return 'pass';
}
sub grade_mhd {
    my $self = shift;
    my $tolMoonHADate = $self->get_tolerance('tolMoonHADate');
    my $tolMoonHADatePercent = $self->get_tolerance('tolMoonHADatePercent');
    warn Dumper({
            tolMoonHADate => $tolMoonHADate,
            tolMoonHADatePercent => $tolMoonHADatePercent,
            'abs(moonHA-realMHD)' => abs($self->{moonHA} - $self->{realMHD}),
            'tolMoonHADate + (tolMoonHADatePercent * abs(realMHD) / 100)' => ($tolMoonHADate + ($tolMoonHADatePercent * abs($self->{realMHD}) / 100)),
    });
    return 'unknown' unless ($self->{moonHA} ne '');
    return 'fail' unless (abs($self->{moonHA} - $self->{realMHD}) <= ($tolMoonHADate + ($tolMoonHADatePercent * abs($self->{realMHD}) / 100)));
    return 'pass';
}

sub grade_shc {
    my $self = shift;
    my $tolSunHACST = $self->get_tolerance('tolSunHACST');
    return 'unknown' unless ($self->{sunHA} ne '');
    return 'fail' unless (abs($self->{sunHA} - $self->{realSHC}) <= $tolSunHACST);
    return 'pass';
}
sub grade_eha {
    my $self = shift;
    my $tolElongHA = $self->get_tolerance('tolElongHA');
    return 'unknown' unless ($self->{elongation} ne '');
    return 'fail' unless (abs($self->{elongation} - $self->{realEHA}) <= $tolElongHA || abs(abs($self->{elongation} - $self->{realEHA}) - 360) <= $tolElongHA);
    return 'pass';
}
sub grade_edt {
    my $self = shift;
    my $tolElongDate = $self->get_tolerance('tolElongDate');
    return 'unknown' unless ($self->{elongation} ne '');
    return 'fail' unless (abs($self->{elongation} - $self->{realEDT}) <= $tolElongDate || abs(abs($self->{elongation} - $self->{realEDT}) - 360) <= $tolElongDate);
    return 'pass';
}
sub grade_up {
    my $self = shift;
    return 'fail' unless ($self->compute_moonUp($self->{dt}));
    return 'pass';
}
sub get_adjoining_observations {
    my $self = shift;
    die '$Moonproject::term and $Moonproject::year must be set if term and year are not provided'
        unless (($self->{term} && $self->{year}) || ($Moonproject::term && $Moonproject::year));
    $self->{term} ||= $Moonproject::term;
    $self->{year} ||= $Moonproject::year;
    # Get most-recent submission of each observation
    my @observations = physdb::queryall("SELECT * FROM moonproject.observation WHERE student = ? AND number <> ? and term = ? and year = ? AND current ORDER BY timestamp ASC", $self->{student}, $self->{number}, $self->{term}, $self->{year});
    # Store timestamps of observations directly before and after current observation if they exist
    my ($last_observation, $next_observation);
    for my $observation (@observations) {
        if (DateTime->compare(DateTime::Format::MySQL->parse_datetime($observation->{date}), $self->{dt}) < 0) {
            $last_observation = $observation;
        }
        else {
            $next_observation = $observation;
            last;
        }
    }
    return ($last_observation, $next_observation);
}
# compute CST for a date.  This is a real number between 0 and 24 which
# gives the number of hours into the day in decimal form.  Ie, 12:00 noon
# is 12.00, 12:30 is 12.50.  It is always given in standard time, so
# if daylight savings is in effect we need to subtract an hour.
sub compute_CST {
    my $self = shift;
    my $date = shift;
    my $cst = $date->clone->set_time_zone('-0600');
    return $cst->hour + $cst->minute/60;
}
# compute moon HA from fists count and degrees/first figure
# this is supposedly exactly the same formula the student uses,
# so except for roundoff error our answer shoudl be identical to theirs.
# We do this to check their mathematics skills. :)
sub compute_moonHA_from_fists {
    my $self = shift;
    my ($fists, $fist_degrees) = @_;
    return $fists * $fist_degrees;
}
# Compute the right moonHA for a given date in epoch seconds.
# we know that Elongation = SunHA -  MoonHA , so we say that
# MoonHA = SunHA - Elongation and calculate using the other
# functions.
sub compute_moonHA_from_date {
    my $self = shift;
    my $date = shift;
    my $cst = $self->compute_CST($date);
    my $elong = $self->compute_elongation_from_date($date);
    my $sunHA = $self->compute_sunHA_from_CST($cst);
    my $moonHA = $sunHA - $elong;
    $moonHA += 360 if ($moonHA < -180);
    $moonHA -= 360 if ($moonHA > 180);
    return $moonHA;
    
}
# compute the Sun HA from CST
# This is again the same formula the student uses.
# We can call it either with the students value to see if
# they did their math correctly, or with the "real CST"
# derived from the date to see if it is actually correct
# for the date.
sub compute_sunHA_from_CST {
    my $self = shift;
    my $cst = shift;
    return ($cst - 12) * 15;
}
# compute elongation from HA.  Same as the student uses.
# we can call it with student HAs to check math or real HAs
# to check accuracy.
sub compute_elongation_from_HA {
    my $self = shift;
    my ($sunHA, $moonHA) = @_;
    my $elong = $sunHA - $moonHA;
    # my $elong = $AZI;
    $elong += 360 if ($elong < 0);
    return $elong;
}
# just a wrapper around the other functions really.
# we compute the real CST, use that to compute real SunHA,
# and then compute MoonHA, all from the date, and then
# compute elongation from these HA values.
sub compute_elongation_from_date {
    my $self = shift;
    my $date = shift;
    if (my $moonrs = $self->get_moon_info($date)) {
        my $midpoint_CST = $self->compute_CST($moonrs->{midpoint});
        my $elong = $self->compute_sunHA_from_CST($midpoint_CST);
        $elong += 360 if ($elong < 0);
        warn "date: " . $date->epoch . ", rise: " . $moonrs->{rise_time}->epoch . " (" . $moonrs->{rise_time} . "), set: " . $moonrs->{set_time}->epoch . " (" . $moonrs->{set_time} . "), midpoint_CST: " . $midpoint_CST . ", elong: " . $elong;
        return $elong;
    }
    else {
        return 0;
    }
}
# returns the number of hours between times $t1 and $t2
sub compute_hourDiff {
    my $self = shift;
    my ($t1, $t2) = @_;
    return abs($t2->epoch-$t1->epoch)/3600;
}
# returns true if the moon was up at $date, false if not.
sub compute_moonUp {
    my $self = shift;
    my $date = shift;
    return $self->get_moon_info($date) ? 1 : 0;
}


sub compute_average_from_fists{
    my $self = shift;
    my ($fists, $fists2, $fists3) = @_;
    my $total = $fists + $fists2 + $fists3;
    my $ave = $total/3;
    return $ave;
}

sub grade_ave {
    my $self = shift;
    my $tolAverageFists = $self->get_tolerance('tolAverageFists');
    return 'unknown' unless ($self->{aveFist} ne '');
    return 'fail' unless (abs($self->{aveFist} - $self->{realAVE}) <= $tolAverageFists || abs(abs($self->{aveFist} - $self->{realAVE}) - 360) <= $tolAverageFists);
    return 'pass';
}

#input date
#this is the same as in the text
#https://quasar.as.utexas.edu/BillInfo/JulianDatesG.html
sub convertToJD{
	my $self = 0;
	my $date = 0;
	my $CTDate = 0;
	my $UTDate = 0;
	my $minute = 0;
	my $hour = 0;
	my $month = 0;
	my $day = 0;
	my $year = 0;
	my $A = 0;
	my $B = 0;
	my $JD =0;

    $self = shift;
    $date = shift;
    #to get to universal time
    $UTDate = $date->clone->set_time_zone('-0600');
    #$UTDate = $date->add( hours => 6 );
    #my $dateTime = $date->clone->set_time_zone('-0600');


    #$self->{dt} = DateTime::Format::MySQL->parse_datetime($self->{date})->set_time_zone('America/Chicago');
    #my ($minute, $hour, $month, $day, $year) = ($dateTime->minute, $dateTime->hour, $dateTime->month, $DateTime->day, $DateTime->year);
    $minute = $UTDate->minute;
    $hour = $UTDate->hour;
    $month = $UTDate->month;
    $day = $UTDate->day;
    $year = $UTDate->year;

    if(($month == 1) or ($month == 2)){
        $year = $year - 1;
        $month = $month + 12;
    }
    $day = $day + ($hour / 24) + ($minute / 60 / 24);

    $A = 0;
    $B = 0;
    $JD = 0;

    $A = int($year / 100);
    $B = 2 - $A + int($A / 4);  
    $JD = int(365.25*($year + 4716)) + int(30.6001*($month + 1)) + $day + $B - 1524.5;

    return $JD;
}


#input date
#same as text pg 78
sub getJDE{
    my $self = shift;
    my $date = shift;

    #central standard
    my $CTDate = $date->clone->set_time_zone('-0600');
    
    #universal time
    my $UTDate = $CTDate->add( hours => 6 );

    my $year1 = $UTDate->year;
    my $littleT = ($year1 - 2000) / 100;
    my $deltaT = 102 + 102 * $littleT + (25.3 * $littleT * $littleT) + 0.37 * ($year1 - 2100);
    my $newTime = $UTDate->add( seconds => $deltaT);

    my $JDE = $self->convertToJD($newTime);

    return $JDE;
}

# input date
#text on page 143, equ. 22.1
sub getT{
    my $self = shift;
    my $date = shift;
    
    my $JDE = $self->getJDE($date);
    my $T = ($JDE - 2451545) / 36525;

    return $T;
}

#input date
#page 338 equ 47.1
sub getLPrime{
    my $self = shift;
    my $date = shift;

    my $T = $self->getT($date);

    my $LPrime = 218.3164477 + 481267.88123421 * $T - (0.0015786 * $T * $T) + ($T * $T * $T) / 538841 - ($T * $T * $T * $T) / 65194000;



    my $remainder = $LPrime / 360.0 - int($LPrime/360);
    my $angle = $remainder * 360;
    
    if ($angle < 0){
        $angle = 360 + $angle;
    }
    return $angle;
}

#input date
#page 338 equ 47.2
sub getD{
    my $self = shift;
    my $date = shift;

    my $T = $self->getT($date);

    my $D = 297.8501921 + 445267.1114034 * $T - (0.0018819 * $T * $T) + ($T * $T * $T) / 545868 - ($T * $T * $T * $T) / 113065000;

    my $remainder = $D / 360.0 - int($D/360);
    my $angle = $remainder * 360;
    
    if ($angle < 0){
        $angle = 360 + $angle;
    }
    return $angle;
}

#input date
#page 338 equ 47.3
sub getM{
    my $self = shift;
    my $date = shift;

    my $T = $self->getT($date);

    my $M = 357.5291092 + 35999.0502909 * $T - (0.0001536 * $T * $T) + ($T * $T * $T) / 24490000;

    my $remainder = $M / 360.0 - int($M/360);
    my $angle = $remainder * 360;
    
    if ($angle < 0){
        $angle = 360 + $angle;
    }
    return $angle;
}


#input date
#page 338 equ 47.4
sub getMPrime{
    my $self = shift;
    my $date = shift;

    my $T = $self->getT($date);

    my $MPrime = 134.9633964 + (477198.8675055 * $T) + (0.0087414 * $T * $T) + (($T * $T * $T) / 69699) - (($T * $T * $T * $T) / 14712000);

    my $remainder = $MPrime / 360.0 - int($MPrime/360);
    my $angle = $remainder * 360;
    
    if ($angle < 0){
        $angle = 360 + $angle;
    }
    return $angle;
}

#input date
#page 338 equ 47.5
sub getF{
    my $self = shift;
    my $date = shift;

    my $T = $self->getT($date);

    my $F = 93.2720950 + (483202.0175233 * $T) - (0.0036539 * $T * $T) - (($T * $T * $T) / 3526000) + (($T * $T * $T * $T) / 863310000);

    my $remainder = $F / 360.0 - int($F/360);
    my $angle = $remainder * 360;
    
    if ($angle < 0){
        $angle = 360 + $angle;
    }
    return $angle;
}

sub getA1{
    my $self = shift;
    my $date = shift;

    my $T = $self->getT($date);
    
    my $A1 = 119.75 + (131.849 * $T);

    my $remainder = $A1 / 360.0 - int($A1/360);
    my $angle = $remainder * 360;
    
    if ($angle < 0){
        $angle = 360 + $angle;
    }
    return $angle;
}

sub getA2{
    my $self = shift;
    my $date = shift;

    my $T = $self->getT($date);

    my $A2 = 53.09 + (479264.290 * $T);

    my $remainder = $A2 / 360.0 - int($A2/360);
    my $angle = $remainder * 360;
    
    if ($angle < 0){
        $angle = 360 + $angle;
    }
    return $angle;
}

sub getA3{
    my $self = shift;
    my $date = shift;

    my $T = $self->getT($date);

    my $A3 = 313.45 + (481266.484 * $T);

    my $remainder = $A3 / 360.0 - int($A3/360);
    my $angle = $remainder * 360;
    
    if ($angle < 0){
        $angle = 360 + $angle;
    }
    return $angle;
}

sub getE{
    my $self = shift;
    my $date = shift;

    my $T = $self->getT($date);

    my $E = 1 - (0.002516 * $T) - (0.0000074 * $T * $T);

    return $E;
}

#input date
#this is chap 22 page 144
sub getNutationLong{
    my $self = shift;
    my $date = shift;

    my $T = $self->getT($date);
    my $D = $self->getD($date);
    my $M = $self->getM($date);
    my $MPrime = $self->getMPrime($date);
    my $F = $self->getF($date);

    my $Omega = 125.04452 - (1934.136261 * $T) + (0.0020708 * $T * $T) + ($T * $T * $T) / 450000;    

    #D,M,M',F,\Omega,Psi Coeff, Psi T coeff, eps coeff, eps T coeff 
    my @valuesFromTable22A = ([0,0,0,0,1,-171996,-174.2,92025,8.9],[-2,0,0,2,2,-13187,-1.6,5736,-3.1],[0,0,0,2,2,-2274,-0.2,977,-0.5],[0,0,0,0,0,2062,0.2,-895,0.5],[0,1,0,0,0,1426,-3.4,54,-0.1],[0,0,1,0,0,712,0.1,-7,0],[-2,1,0,2,2,-517,1.2,224,-0.6],[0,0,0,2,1,-386,-0.4,200,0],[0,0,1,2,2,-301,0,129,-0.1],[-2,-1,0,2,2,217,-0.5,-95,0.3],[-2,0,1,0,0,-158,0,0,0],[-2,0,0,2,1,129,0.1,-70,0],[0,0,-1,2,2,123,0,-53,0],[2,0,0,0,0,63,0,0,0],[0,0,1,0,1,63,0.1,-33,0],[2,0,-1,2,2,-59,0,26,0],[0,0,-1,0,1,-58,-0.1,32,0],[0,0,1,2,1,-51,0,27,0],[-2,0,2,0,0,48,0,0,0],[0,0,-2,2,1,46,0,-24,0],[2,0,0,2,2,-38,0,16,0],[0,0,2,2,2,-31,0,13,0],[0,0,2,0,0,29,0,0,0],[-2,0,1,2,2,29,0,-12,0],[0,0,0,2,0,26,0,0,0],[-2,0,0,2,0,-22,0,0,0],[0,0,-1,2,1,21,0,-10,0],[0,2,0,0,0,17,-0.1,0,0],[2,0,-1,0,1,16,0,-8,0],[-2,2,0,2,2,-16,0.1,7,0],[0,1,0,0,1,-15,0,9,0],[-2,0,1,0,1,-13,0,7,0],[0,-1,0,0,1,-12,0,6,0],[0,0,2,-2,0,11,0,0,0],[2,0,-1,2,1,-10,0,5,0],[2,0,1,2,2,-8,0,3,0],[0,1,0,2,2,7,0,-3,0],[-2,1,1,0,0,-7,0,0,0],[0,-1,0,2,2,-7,0,3,0],[2,0,0,2,1,-7,0,3,0],[2,0,1,0,0,6,0,0,0],[-2,0,2,2,2,6,0,-3,0],[-2,0,1,2,1,6,0,-3,0],[2,0,-2,0,1,-6,0,3,0],[2,0,0,0,1,-6,0,3,0],[0,-1,1,0,0,5,0,0,0],[-2,-1,0,2,1,-5,0,3,0],[-2,0,0,0,1,-5,0,3,0],[0,0,2,2,1,-5,0,3,0],[-2,0,2,0,1,4,0,0,0],[-2,1,0,2,1,4,0,0,0],[0,0,1,-2,0,4,0,0,0],[-1,0,1,0,0,-4,0,0,0],[-2,1,0,0,0,-4,0,0,0],[1,0,0,0,0,-4,0,0,0],[0,0,1,2,0,3,0,0,0],[0,0,-2,2,2,-3,0,0,0],[-1,-1,1,0,0,-3,0,0,0],[0,1,1,0,0,-3,0,0,0],[0,-1,1,2,2,-3,0,0,0],[2,-1,-1,2,2,-3,0,0,0],[0,0,3,2,2,-3,0,0,0],[2,-1,0,2,2,-3,0,0,0]);

    my $DeltaPsi = 0;
    my $DeltaEpsilon = 0;

    for (my $i=0; $i<(scalar @valuesFromTable22A); $i++){
        my $trigArgument = Astro::Coord::ECI::Utils::deg2rad(($valuesFromTable22A[$i][0] * $D) + ($valuesFromTable22A[$i][1] * $M) + ($valuesFromTable22A[$i][2] * $MPrime) + ($valuesFromTable22A[$i][3] * $F) + ($valuesFromTable22A[$i][4] * $Omega));

        $DeltaPsi += ($valuesFromTable22A[$i][5] + $valuesFromTable22A[$i][6] * $T) / (3600*10000) * sin($trigArgument);
        $DeltaEpsilon += ($valuesFromTable22A[$i][7] + $valuesFromTable22A[$i][8] * $T) / (3600*10000) *cos($trigArgument);
    }

    return ($DeltaPsi,$DeltaEpsilon);
}

#input date
sub getSunMeanLatitudeDeg{
    my $self = shift;
    my $date = shift;

    my $T = $self->getT($date);
    my $L = 280.4665 + (36000.7698 * $T);

    return $L;
}

#obliquity of the ecliptic, input date, correction
sub getObliquityEcliptic{
    my $self = shift;
    my $date = shift;

    my ($DeltaPsi,$DeltaEpsilon) = $self->getNutationLong($date);

    my $T = $self->getT($date);

    #need to add correction in chapter 22 
    my $epsilon = 23.43929111 - (0.0130041666 * $T) - (0.00000016388888 * $T * $T) + (0.00000050361111 * $T * $T * $T);

    return $epsilon + $DeltaEpsilon;
}

#the logic in the sub routine matches Meeus--have not checked the validity of the inputs
sub getSigmaLRB{
    my $self = shift;
    my ($LPrime, $D, $M, $MPrime, $F, $A1, $A2, $A3, $E) = @_;

    #each entry in the array is [$D, $M, $MPrime, $F]
    #these are perfect. I have checked them visually and with a difference checker with an online version of the code on github. https://github.com/Fabiz/MeeusJs/blob/master/lib/Astro.Moon.js
    my @valuesFromTable47B = ([0,0,0,1,5128122],[0,0,1,1,280602],[0,0,1,-1,277693],[2,0,0,-1,173237],[2,0,-1,1,55413],[2,0,-1,-1,46271],[2,0,0,1,32573],[0,0,2,1,17198],[2,0,1,-1,9266],[0,0,2,-1,8822],[2,-1,0,-1,8216],[2,0,-2,-1,4324],[2,0,1,1,4200],[2,1,0,-1,-3359],[2,-1,-1,1,2463],[2,-1,0,1,2211],[2,-1,-1,-1,2065],[0,1,-1,-1,-1870],[4,0,-1,-1,1828],[0,1,0,1,-1794],[0,0,0,3,-1749],[0,1,-1,1,-1565],[1,0,0,1,-1491],[0,1,1,1,-1475],[0,1,1,-1,-1410],[0,1,0,-1,-1344],[1,0,0,-1,-1335],[0,0,3,1,1107],[4,0,0,-1,1021],[4,0,-1,1,833],[0,0,1,-3,777],[4,0,-2,1,671],[2,0,0,-3,607],[2,0,2,-1,596],[2,-1,1,-1,491],[2,0,-2,1,-451],[0,0,3,-1,439],[2,0,2,1,422],[2,0,-3,-1,421],[2,1,-1,1,-366],[2,1,0,1,-351],[4,0,0,1,331],[2,-1,1,1,315],[2,-2,0,-1,302],[0,0,1,3,-283],[2,1,1,-1,-229],[1,1,0,-1,223],[1,1,0,1,223],[0,1,-2,-1,-220],[2,1,-1,-1,-220],[1,0,1,1,-185],[2,-1,-2,-1,181],[0,1,2,1,-177],[4,0,-2,-1,176],[4,-1,-1,-1,166],[1,0,1,-1,-164],[4,0,1,-1,132],[1,0,-1,-1,-119],[4,-1,0,-1,115],[2,-2,0,1,107]);
    my @valuesFromTable47A = ([0,0,1,0,6288774,-20905355],[2,0,-1,0,1274027,-3699111],[2,0,0,0,658314,-2955968],[0,0,2,0,213618,-569925],[0,1,0,0,-185116,48888],[0,0,0,2,-114332,-3149],[2,0,-2,0,58793,246158],[2,-1,-1,0,57066,-152138],[2,0,1,0,53322,-170733],[2,-1,0,0,45758,-204586],[0,1,-1,0,-40923,-129620],[1,0,0,0,-34720,108743],[0,1,1,0,-30383,104755],[2,0,0,-2,15327,10321],[0,0,1,2,-12528,0],[0,0,1,-2,10980,79661],[4,0,-1,0,10675,-34782],[0,0,3,0,10034,-23210],[4,0,-2,0,8548,-21636],[2,1,-1,0,-7888,24208],[2,1,0,0,-6766,30824],[1,0,-1,0,-5163,-8379],[1,1,0,0,4987,-16675],[2,-1,1,0,4036,-12831],[2,0,2,0,3994,-10445],[4,0,0,0,3861,-11650],[2,0,-3,0,3665,14403],[0,1,-2,0,-2689,-7003],[2,0,-1,2,-2602,0],[2,-1,-2,0,2390,10056],[1,0,1,0,-2348,6322],[2,-2,0,0,2236,-9884],[0,1,2,0,-2120,5751],[0,2,0,0,-2069,0],[2,-2,-1,0,2048,-4950],[2,0,1,-2,-1773,4130],[2,0,0,2,-1595,0],[4,-1,-1,0,1215,-3958],[0,0,2,2,-1110,0],[3,0,-1,0,-892,3258],[2,1,1,0,-810,2616],[4,-1,-2,0,759,-1897],[0,2,-1,0,-713,-2117],[2,2,-1,0,-700,2354],[2,1,-2,0,691,0],[2,-1,0,-2,596,0],[4,0,1,0,549,-1423],[0,0,4,0,537,-1117],[4,-1,0,0,520,-1571],[1,0,-2,0,-487,-1739],[2,1,0,-2,-399,0],[0,0,2,-2,-381,-4421],[1,1,1,0,351,0],[3,0,-2,0,-340,0],[4,0,-3,0,330,0],[2,-1,2,0,327,0],[0,2,1,0,-323,1165],[1,1,-1,0,299,0],[2,0,3,0,294,0],[2,0,-1,-2,0,8752]);


    #these are on page 342 in Meeus--they match
    my $sumL = 3958 * sin(Astro::Coord::ECI::Utils::deg2rad($A1)) + 1962 * sin(Astro::Coord::ECI::Utils::deg2rad($LPrime - $F)) + 318 * sin(Astro::Coord::ECI::Utils::deg2rad($A2));
    my $sumR = 0;
    my $sumB = -2235 * sin(Astro::Coord::ECI::Utils::deg2rad($LPrime)) + 382 * sin(Astro::Coord::ECI::Utils::deg2rad($A3)) + 175 * sin(Astro::Coord::ECI::Utils::deg2rad($A1 - $F)) + 175 * sin(Astro::Coord::ECI::Utils::deg2rad($A1 + $F)) + 127 * sin(Astro::Coord::ECI::Utils::deg2rad($LPrime - $MPrime)) - 115 * sin(Astro::Coord::ECI::Utils::deg2rad($LPrime + $MPrime));

    #sigmaB is off by 10

    for (my $i=0; $i<(scalar @valuesFromTable47A); $i++){

        #this matches with what is in Meeus. pg 338
        my $trigArgument = Astro::Coord::ECI::Utils::deg2rad(($valuesFromTable47A[$i][0] * $D) + ($valuesFromTable47A[$i][1] * $M) + ($valuesFromTable47A[$i][2] * $MPrime) + ($valuesFromTable47A[$i][3] * $F));

        if ($valuesFromTable47A[$i][1] == 0){
            $sumL += ($valuesFromTable47A[$i][4]) * sin($trigArgument);
            $sumR += ($valuesFromTable47A[$i][5]) * cos($trigArgument);
        }

        if (($valuesFromTable47A[$i][1] == 1) or ($valuesFromTable47A[$i][1] == -1)){
            $sumL += $E * ($valuesFromTable47A[$i][4]) * sin($trigArgument);
            $sumR += $E * ($valuesFromTable47A[$i][5]) * cos($trigArgument);
        }

        if (($valuesFromTable47A[$i][1] == 2) or ($valuesFromTable47A[$i][1] == -2)){
            $sumL += $E * $E * ($valuesFromTable47A[$i][4]) * sin($trigArgument);
            $sumR += $E * $E * ($valuesFromTable47A[$i][5]) * cos($trigArgument);
        }
    }

    for (my $i=0; $i<(scalar @valuesFromTable47B); $i++){

        #this matches Meeus
        my $trigArgument = Astro::Coord::ECI::Utils::deg2rad($valuesFromTable47B[$i][0] * $D + $valuesFromTable47B[$i][1] * $M + $valuesFromTable47B[$i][2] * $MPrime + $valuesFromTable47B[$i][3] * $F);

        if ($valuesFromTable47A[$i][1] == 0){
            $sumB += ($valuesFromTable47B[$i][4] )*sin($trigArgument);
        }

        if (($valuesFromTable47A[$i][1] == 1) or ($valuesFromTable47A[$i][1] == -1)){
            $sumB += $E * ($valuesFromTable47B[$i][4])*sin($trigArgument);
        }

        if (($valuesFromTable47A[$i][1] == 2) or ($valuesFromTable47A[$i][1] == -2)){
            $sumB += $E * $E * ($valuesFromTable47B[$i][4])*sin($trigArgument);
        }
    }

    return ($sumL, $sumR, $sumB)

}

#input date
sub computeLongitudeLatitudeDistanceHorizonParallax{
    my $self = shift;
    my $date = shift;
    
    my $T = $self->getT($date);

    #moon's mean longitude in degrees
    my $LPrime = $self->getLPrime($date);
    #mean elongation of the moon in degrees
    my $D = $self->getD($date);
    #sun's mean anomaly in degrees
    my $M = $self->getM($date);
    #moon's mean anomaly in degrees
    my $MPrime = $self->getMPrime($date);
    #moon's argumment of latitude
    my $F = $self->getF($date);
    #corrections in degrees-Matches Meeus pg 338
    my $A1 = $self->getA1($date);
    my $A2 = $self->getA2($date);
    my $A3 = $self->getA3($date);
    #eccentricity. Matches Meeus pg. 338
    my $E = $self->getE($date);

    #nutation in longitude--Need to Inlcuded the table parameters form pg 145-146
    my ($DeltaPsi,$DeltaEpsilon) = $self->getNutationLong($date);
    
    my $epsilon = $self->getObliquityEcliptic($date);

    #sums of arguments from table 47
    my ($SigmaL, $SigmaR, $SigmaB) = $self->getSigmaLRB($LPrime, $D, $M, $MPrime, $F, $A1, $A2, $A3, $E);

    #coordinates of the moon
    #geocentric longitude of the center of the moon
    my $lambda = $LPrime + $SigmaL/1000000;
    #geocentric latitude of the center of the moon
    my $beta =  $SigmaB/1000000;

    #distance in kilometers between centers of Earht and Moon
    my $Delta = 385000.56 + $SigmaR/1000;

    #equitorial horizontal parallax of the moon page 337
    my $pi = asin(Astro::Coord::ECI::Utils::deg2rad(6378.14 / $Delta));

    #apparent longitude of the moon
    $lambda = $lambda + $DeltaPsi;

    $epsilon = $epsilon;

    return ($lambda, $beta, $Delta, $epsilon);

}

sub getSigmaL{
    my $self = shift;
    my $date = shift;
    
    my $T = $self->getT($date);

    #moon's mean longitude in degrees
    my $LPrime = $self->getLPrime($date);
    #mean elongation of the moon in degrees
    my $D = $self->getD($date);
    #sun's mean anomaly in degrees
    my $M = $self->getM($date);
    #moon's mean anomaly in degrees
    my $MPrime = $self->getMPrime($date);
    #moon's argumment of latitude
    my $F = $self->getF($date);
    #corrections in degrees-Matches Meeus pg 338
    my $A1 = $self->getA1($date);
    my $A2 = $self->getA2($date);
    my $A3 = $self->getA3($date);
    #eccentricity. Matches Meeus pg. 338
    my $E = $self->getE($date);

    #nutation in longitude--Need to Inlcuded the table parameters form pg 145-146
    my ($DeltaPsi,$DeltaEpsilon) = $self->getNutationLong($date);
    
    my $epsilon = $self->getObliquityEcliptic($date);

    #sums of arguments from table 47
    my ($SigmaL, $SigmaR, $SigmaB) = $self->getSigmaLRB($LPrime, $D, $M, $MPrime, $F, $A1, $A2, $A3, $E);

    return $SigmaL;
}

sub getSigmaB{
    my $self = shift;
    my $date = shift;
    
    my $T = $self->getT($date);

    #moon's mean longitude in degrees
    my $LPrime = $self->getLPrime($date);
    #mean elongation of the moon in degrees
    my $D = $self->getD($date);
    #sun's mean anomaly in degrees
    my $M = $self->getM($date);
    #moon's mean anomaly in degrees
    my $MPrime = $self->getMPrime($date);
    #moon's argumment of latitude
    my $F = $self->getF($date);
    #corrections in degrees-Matches Meeus pg 338
    my $A1 = $self->getA1($date);
    my $A2 = $self->getA2($date);
    my $A3 = $self->getA3($date);
    #eccentricity. Matches Meeus pg. 338
    my $E = $self->getE($date);

    #nutation in longitude--Need to Inlcuded the table parameters form pg 145-146
    my ($DeltaPsi,$DeltaEpsilon) = $self->getNutationLong($date);
    
    my $epsilon = $self->getObliquityEcliptic($date);

    #sums of arguments from table 47
    my ($SigmaL, $SigmaR, $SigmaB) = $self->getSigmaLRB($LPrime, $D, $M, $MPrime, $F, $A1, $A2, $A3, $E);

    return $SigmaB;
}

sub getSigmaR{
    my $self = shift;
    my $date = shift;
    
    my $T = $self->getT($date);

    #moon's mean longitude in degrees
    my $LPrime = $self->getLPrime($date);
    #mean elongation of the moon in degrees
    my $D = $self->getD($date);
    #sun's mean anomaly in degrees
    my $M = $self->getM($date);
    #moon's mean anomaly in degrees
    my $MPrime = $self->getMPrime($date);
    #moon's argumment of latitude
    my $F = $self->getF($date);
    #corrections in degrees-Matches Meeus pg 338
    my $A1 = $self->getA1($date);
    my $A2 = $self->getA2($date);
    my $A3 = $self->getA3($date);
    #eccentricity. Matches Meeus pg. 338
    my $E = $self->getE($date);

    #nutation in longitude--Need to Inlcuded the table parameters form pg 145-146
    my ($DeltaPsi,$DeltaEpsilon) = $self->getNutationLong($date);
    
    my $epsilon = $self->getObliquityEcliptic($date);

    #sums of arguments from table 47
    my ($SigmaL, $SigmaR, $SigmaB) = $self->getSigmaLRB($LPrime, $D, $M, $MPrime, $F, $A1, $A2, $A3, $E);

    return $SigmaR;
}

#input date
sub getRAandDEC{
    my $self = shift;
    my $date = shift;
    
    my ($lambda, $beta, $Delta, $epsilon) = 
    $self->computeLongitudeLatitudeDistanceHorizonParallax($date);

    my $T = $self->getT($date);



    #right ascension
    my $RA = Astro::Coord::ECI::Utils::rad2deg(
        atan2(
            (
                (sin(
                    Astro::Coord::ECI::Utils::deg2rad(
                        $lambda
                    )
                ) * cos(
                    Astro::Coord::ECI::Utils::deg2rad(
                        $epsilon)
                    )
                ) - (
                    (sin(
                        Astro::Coord::ECI::Utils::deg2rad(
                            $beta)
                        ) / cos(
                            Astro::Coord::ECI::Utils::deg2rad(
                                $beta)
                            )
                    ) * sin(
                        Astro::Coord::ECI::Utils::deg2rad(
                            $epsilon)
                            )
                    )
            ), (cos(
                Astro::Coord::ECI::Utils::deg2rad(
                    $lambda)
                    )
                )
        )
    );

    if($RA < 0){
    	$RA = $RA + 360;
    }

    #declination
    my $DEC = Astro::Coord::ECI::Utils::rad2deg(asin((sin(Astro::Coord::ECI::Utils::deg2rad($beta)) * cos(Astro::Coord::ECI::Utils::deg2rad($epsilon))) + (cos(Astro::Coord::ECI::Utils::deg2rad($beta)) * sin((Astro::Coord::ECI::Utils::deg2rad($epsilon)) * sin(Astro::Coord::ECI::Utils::deg2rad($lambda))))));

    return ($RA, $DEC);
}

#this matches the text and is working
sub getTJD{
	my $self = shift;
    my $date = shift;
    my $JD = $self->convertToJD($date);
    my $T = ($JD - 2451545) / 36525;
    return $T;
}

#input date
#this matches the text and is working pg 88
sub getMeanSiderealTimeGreenwich{
    my $self = shift;
    my $date = shift;
    my $JD = $self->convertToJD($date);
    my $T = ($JD - 2451545) / 36525;

    #equ 12.4 pg 88
    my $theta = 280.46061837 + (360.98564736629 * ($JD - 2451545.0)) + (0.000387933 * $T * $T) - (($T * $T * $T) / 38710000);

    my $remainder = $theta / 360.0 - int($theta / 360);
    
    my $angle = 0;

    if ($remainder < 0){
        $angle = 360 + ($remainder * 360.0);
    }
    else {
    	$angle = ($remainder * 360.0);
    }
    return $JD;
    #return $theta;
}

#input date
sub getHaAziAlt{
    my $self = shift;
    my $date = shift;

    my ($RA, $DEC) = $self->getRAandDEC($date); 

    #mean sidereal time at greenwich in degrees
    my $theta = $self->getMeanSiderealTimeGreenwich($date);

    #latitude of observer
    my $lat = Astro::Coord::ECI::Utils::deg2rad(44.9778);
    
    #longitude of observer
    my $long = Astro::Coord::ECI::Utils::deg2rad(93.2650);

    #hour angle of moon this checks out
    my $H = $theta - 93.2650 - $RA;

    if ($H < 0){
    	$H = $H + 90;
    }

    else{
    	$H = $H - 270;
    }


    #azimuthal angle
    my $AZI = Astro::Coord::ECI::Utils::rad2deg(atan2(sin(Astro::Coord::ECI::Utils::deg2rad($H)), ((cos(Astro::Coord::ECI::Utils::deg2rad($H)) * sin($lat)) - ((sin(Astro::Coord::ECI::Utils::deg2rad($DEC) / cos(Astro::Coord::ECI::Utils::deg2rad($DEC))) * cos($lat))))));
    
    #altitude
    my $altitude =  Astro::Coord::ECI::Utils::rad2deg(asin((sin($lat) * sin(Astro::Coord::ECI::Utils::deg2rad($DEC))) + (cos($lat) * cos(Astro::Coord::ECI::Utils::deg2rad($DEC)) * cos(Astro::Coord::ECI::Utils::deg2rad($H)))));


    return ($H, $AZI, $altitude);
    #return ($theta, $AZI, $altitude);
}


#off by 270 degrees
sub getHA{
    my $self = shift;
    my $date = shift;

    my ($H, $AZI, $altitude) = $self->getHaAziAlt($date);

    return $H;
}

sub getAZI{
    my $self = shift;
    my $date = shift;

    my ($H, $AZI, $altitude) = $self->getHaAziAlt($date);

    
    return $AZI;
}

sub getALT{
	my $self = shift;
    my $date = shift;

    my ($H, $AZI, $altitude) = $self->getHaAziAlt($date);

    return $altitude;
}

sub getRA{
    my $self = shift;
    my $date = shift;

    my ($RA, $DEC) = $self->getRAandDEC($date); 

    return $RA;
}

sub getDEC{
    my $self = shift;
    my $date = shift;

    my ($RA, $DEC) = $self->getRAandDEC($date); 

    return $DEC;
}

sub getNewElongation{
    my $self = shift;
    my $date = shift;
    
    my $hour = $date->hour;
    my $minute = $date->minute;

    my $MHA = $self->getHA($date); # June 27 2018 0930: -229.627643735931
    
    my $SunHA = (($hour + $minute/60) - 12) * 15; # June 27 2018 0930: -37.5
	
    my $AZI = $self->getAZI($date); # June 27 2018 0930: 104.486367178372

    my $elongation = $SunHA - $MHA; # June 27 2018 0930: -37.5 - (-229.627643735931) = 191.12
    # my $elongation = $AZI;
    my ($RA, $DEC) = $self->getRAandDEC($date); # June 27 2018 0930: RA: 269.270552255631, DEC: -20.3075638354576
    # real RA is: 266.6083   
    if ($elongation < 0){
    	$elongation = $elongation + 360; 
    }
 
    #return $DEC;
    return $self->getMeanSiderealTimeGreenwich($date);
}

1;


