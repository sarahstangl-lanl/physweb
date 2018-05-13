package Moonproject::Student;

use strict;
use warnings;

use physdb;
use Data::Dumper;
use Moonproject;
use Moonproject::TA;
use Moonproject::Observation;
use MasonHelper;

sub new {
    my $class = shift;
    my $self = { @_ };

    die "gradesid is required" unless ($self->{gradesid});

    my $classids = Moonproject::get_classids(admin => 1);

    return undef unless (@$classids);

    my $student_sth = physdb::query("
        SELECT l.studentid, u.x500, u.dispname AS name, l.section, CONCAT(d.first_name, ' ', d.last_name) AS ta_name, d.uid AS ta_uid, IFNULL(s.email, CONCAT(u.x500, '\@umn.edu')) AS email, d.email AS ta_email, s.fist_degrees AS fistdegrees, s.accepted_contract, s.userid
        FROM grades.users u
        LEFT JOIN grades.classlist l ON u.id = l.userid AND l.classid " . _in(@$classids) . "
        LEFT JOIN members m ON m.memberof = l.classid
        LEFT JOIN directory d ON d.uid = m.uid
        LEFT JOIN moonproject.student s ON s.userid = u.id
        WHERE u.id = ?", @$classids, $self->{gradesid});
    my $student = $student_sth->fetchrow_hashref;

    return undef unless ($student);

    unless (defined $student->{userid}) {
        physdb::query("INSERT INTO moonproject.student (x500, userid) VALUES (?,?)", $student->{x500}, $self->{gradesid});
    }

    for my $col (@{ $student_sth->{NAME} }) {
        $self->{$col} = $student->{$col};
    }

    bless $self, $class;

    return $self;
}

sub update {
    my $self = shift;
    while (@_) {
        my $key = (shift @_);
        my $value = (shift @_);
        $self->{$key} = $value;
    }
    physdb::query("UPDATE moonproject.student SET email = ?, fist_degrees = ?, accepted_contract = ? WHERE userid = ?", $self->{email}, $self->{fistdegrees}, $self->{accepted_contract}, $self->{gradesid});
    return $self;
}

sub ta {
    my $self = shift;
    return $self->{ta} if ($self->{ta});
    $self->{ta} = Moonproject::TA->new(uid => $self->{ta_uid});
}

sub observation_numbers {
    my $self = shift;
    return map { $_->{number} } $self->current_observations(@_);
}

sub current_observations {
    my $self = shift;
    my $args = { @_ };
    $args->{sort_field} ||= 'number';
    my $term = $args->{term} || $Moonproject::term;
    my $year = $args->{year} || $Moonproject::year;
    die '$Moonproject::term and $Moonproject:year must be set if term and year not provided.'
        unless ($term && $year);
    my @args = ($self->{gradesid}, $term, $year);
    my $filter_clause = '';
    if ($args->{filter}) {
        $filter_clause = 'AND taAccepted=?';
        push @args, ($args->{filter} eq 'unreviewed' ? 'unset' : $args->{filter});
    }
    return map { Moonproject::Observation->new(id => $_->{id}) } physdb::queryall("SELECT id FROM moonproject.observation WHERE student = ? AND term = ? AND year = ? AND current $filter_clause ORDER BY $args->{sort_field} ASC", @args);
}

sub dirty_observations {
    my $self = shift;
    my @dirty;
    for my $observation ($self->current_observations) {
        if (my $is_dirty = $observation->ta_tolerance_check && $observation->{taAccepted} eq 'unset') {
            push (@dirty, { observation => $observation, message => $is_dirty });
        }
    }
    return @dirty;
}

1;
