package MasonHelper;

use strict;
use warnings;
use Exporter 'import';
our @EXPORT = qw/_h _u _args _arg_pair _in _p/;


sub _h {
    my $m = HTML::Mason::Request->instance;
    return $m->interp->apply_escapes(defined $_[0] ? $_[0] : '', 'h');
}

sub _u {
    my $m = HTML::Mason::Request->instance;
    return $m->interp->apply_escapes(defined $_[0] ? $_[0] : '', 'u');
}

sub _arg_pair {
    my ($arg, $value) = @_;
    if (ref $value eq 'ARRAY') {
        return join('&', map { _arg_pair($arg, $_) } @$value);
    }
    return _u($arg) . '=' . _u($value);
}

# Pass hash of key/value pairs and a URL-compatible string will be returned
# i.e arg1 => value1, arg2 => value2, arg3 => [ arrayval1, arrayval2 ]
#   -> arg1=value1&arg2=value2&arg3=arrayval1&arg3=arrayval2
sub _args {
    my %args = @_;
    return join('&', map { _arg_pair($_, $args{$_}) } keys %args);
}

# Generate an SQL IN block with scalar(@_) placeholders, i.e. IN (?, ?, ?)
sub _in {
    return 'IN (' . join(', ', map { '?' } @_) . ')';
}

# Returns an html escaped and PRE wrapped string from the argument
sub _p {
    return "<PRE>". _h(shift()) ."</PRE>";
}

1;
