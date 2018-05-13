package QueryStoreHash;

# A specialized hash for use by pathquery which stores 0+ values associated with a key
# Based on Tie::AppendHash

use strict;
use Tie::Hash;

use vars qw(@ISA);
@ISA = qw(Tie::StdHash);

sub STORE {
    my ($self, $key, $value) = @_;
    $self->{$key} = [$value];
}

sub add {
    my ($self, $key, $value) = @_;
    push @{$self->{$key}}, $value;
}


sub FETCH {
    my ($self, $key) = @_;
    if (defined($self->{$key})) {
        return $self->{$key}[0];
    } else {
        return undef;
    }
}

sub getOne {
    my ($self, $key) = @_;
    return $self->FETCH($key);
}

sub get {
    my ($self, $key) = @_;
    return $self->{$key};
}

1;