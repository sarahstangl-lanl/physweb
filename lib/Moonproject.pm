package Moonproject;

use strict;
use warnings;

use physdb;

our ($term, $year);

our $config = {
    dayNumber_min => 1,
    dayNumber_max => 366,

    cst_min => 0,
    cst_max => 24,

    phaseNumber_min => 0,
    phaseNumber_max => 8,

    moonHA_min => 0,
    moonHA_max => 720,

    sunHA_min => 0,
    sunHA_max => 180,

    elongation_min => 0,
    elongation_max => 360,

    sketches => [
        { name => 'A', src =>"/images/moonproject/moon00.jpg", number => 0 },
        { name => 'B', src =>"/images/moonproject/moon03.jpg", number => 0.5 },
        { name => 'C', src =>"/images/moonproject/moon05.jpg", number => 1 },
        { name => 'D', src =>"/images/moonproject/moon07.jpg", number => 1.5 },
        { name => 'E', src =>"/images/moonproject/moon08.jpg", number => 2 },
        { name => 'F', src =>"/images/moonproject/moon09.jpg", number => 2.5 },
        { name => 'G', src =>"/images/moonproject/moon10.jpg", number => 3 },
        { name => 'H', src =>"/images/moonproject/moon15.jpg", number => 3.5 },
        { name => 'I', src =>"/images/moonproject/moon16.jpg", number => 4 },
        { name => 'J', src =>"/images/moonproject/moon18.jpg", number => 4.5 },
        { name => 'K', src =>"/images/moonproject/moon20.jpg", number => 5 },
        { name => 'L', src =>"/images/moonproject/moon22.jpg", number => 5.5 },
        { name => 'M', src =>"/images/moonproject/moon23.jpg", number => 6 },
        { name => 'N', src =>"/images/moonproject/moon24.jpg", number => 6.5 },
        { name => 'O', src =>"/images/moonproject/moon25.jpg", number => 7 },
        { name => 'P', src =>"/images/moonproject/moon27.jpg", number => 7.5 },
    ],
};

sub get_classids {
    my %args = @_;
    die '$Moonproject::year and $Moonproject:term must be set' unless ($year && $term);
    $args{labs_only} = 1 unless (defined $args{labs_only});
    my $lab_clause = $args{labs_only} ? ' AND component = "LAB"' : '';
    my $ta_clause = '';
    my @args = ($year, $term);
    unless ($args{admin}) {
        die "uid is required unless admin" unless ($args{uid});
        $ta_clause = ' AND classid IN (SELECT memberof FROM members WHERE uid = ?)';
        push @args, $args{uid};
    }
    return physdb::queryarray("SELECT classid FROM classlist WHERE name = 'Ast 1001' AND year = ? AND quarter = ? $lab_clause $ta_clause", @args);
}

1;
