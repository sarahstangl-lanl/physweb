package Tablesearch::Output::Array;

use strict;
use warnings;

sub new {
    my($class) = shift;

    bless {
    }, $class;
}


sub name {
	return 'Array';
}

sub start_header {
	my $self = shift;
	my %args = @_;

	my $ts = $args{self};

    $ts->{tmp}->{out}->{header} = [];
}

sub header {
	my $self = shift;
	my %args = @_;

    my $ts = $args{self};
    my $name = $args{name};
    my $sortname = $args{sortname};

    push @{$ts->{tmp}->{out}->{header}}, { display_name => $name, name => $sortname };
}

sub end_header {

}

sub start_row {
	my $self = shift;
	my %args = @_;

    my $ts = $args{self};

    $ts->{tmp}->{cur_row} = [];
}

sub row_data {
	my $self = shift;
	my %args = @_;

    my $ts = $args{self};
    my $field_param = $args{field_param};
    my $data_format = $args{data_format};
    my $value = $args{value};
    my %row = %{$args{row}};
    my $i = $args{i};

    push @{$ts->{tmp}->{cur_row}}, $value;
}

sub end_row {
	my $self = shift;
	my %args = @_;

    my $ts = $args{self};

    push @{$ts->{tmp}->{out}->{data}}, $ts->{tmp}->{cur_row};
}

sub begin {

}

sub end {

}

1;
