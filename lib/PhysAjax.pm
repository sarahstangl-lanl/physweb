package PhysAjax;

use strict;
use warnings;
use JSON;
use Exporter 'import';

our @EXPORT = qw/print_ajax/;

sub print_ajax {
    my $object = shift;

    my $m = HTML::Mason::Request->instance || die "Failed to get Mason request instance";

    # Clear out already-generated template output
    $m->clear_buffer;

    # Output JSON
    $m->print("/*-secure-\n" . to_json($object) . "\n*/");

    # Prevent displaying remainder of template
    $m->abort;
}
