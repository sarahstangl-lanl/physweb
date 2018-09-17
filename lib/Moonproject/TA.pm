package Moonproject::TA;

use strict;
use warnings;

sub new {
    my $class = shift;
    my $self = { @_ };
    my $defaults = {
        id => undef,
        tolObsToSubmitDiff => 72 * 60 * 60, # 72 hours
        tolObsToLastDiff => 12 * 60 * 60, # 12 hours
        tolCST => 0.1,
        tolDayNumber => 0,
        tolPhaseNumber => 0.8,
        tolAverageFists => 0.1,
        tolMoonHAFists => 1,
        tolMoonHADate => 10,
        tolMoonHADatePercent => 10,
        tolSunHACST => 1,
        tolElongHA => 1,
        tolElongDate => 30,
        detailedObs => 'yes',
        forceRegrading => 'no',
        showIntermediateGrades => 'yes',
        sortStudentsBy => 'lastname',
        # tolMoonAZMFists => 10,
        uid => undef,
    };
    if ($self->{uid}) {
        # Fetch TA row
        my $query = "SELECT ta.*, CONCAT(d.first_name, ' ', d.last_name) AS name FROM moonproject.ta ta JOIN directory d ON ta.uid = d.uid WHERE ta.uid = ?";
        my $ta_sth = physdb::query($query, $self->{uid});
        my $ta = $ta_sth->fetchrow_hashref;
        # Create new row if none found
        unless ($ta) {
            my @cols = sort keys %$defaults;
            $self = { %$defaults, %$self };
            physdb::query("INSERT INTO moonproject.ta (" . join(',', @cols) . ") VALUES (" . join(',', map { '?' } @cols) . ")", map { $self->{$_} } @cols);
            $ta = physdb::queryfirstrow($query, $self->{uid});
        }
        for my $col (@{ $ta_sth->{NAME} }) {
            $self->{$col} = $ta->{$col};
        }
    }
    else {
        $self = $defaults;
    }

    bless $self, $class;

    return $self;
}

1;
