package magicpaginator;

#
# The magicpaginator is was designed originally for tablesearch.pm/.comp to deal with huge huge huge
# lists of pages. A few options already existed, but we wanted a way that would still let us get anywhere
# in the list. (One option was Data::SpreadPagination, but it didn't let us get anywhere.)
# 
# So if you have a list of pages from 1 .. 10,000, we want the available pages to be
# like 1, 2, 3, 4, 5, 1000, 2000, 3000, ... and so on.
#

use warnings;
use strict;
use Exporter qw(import);

use List::Util qw(max);
use POSIX ();

sub new {
    my $class = shift;
    my %args = @_;
    
    my %defaults = (
    	'cur_page' => undef,
    	'pages' => undef,
    	
        'padding' => 20,
        'approx_entries' => 40 # It will be about this # + (padding*4)
    );
    
    my %meow = (%defaults, %args);
    my $self = \%meow;
    
    bless($self, $class);
    return $self;  
}

sub get_pages {
	my ($self) = @_;
	
	my @pages;
	
	my $pageincr = 1;
	for (my $page=1; $page<=$self->{pages}; ) {
		push @pages, $page;
	
		# If we are at the end of the 1 .. #{padding} block or the (cur_page - #{padding}) .. (cur_page + #{padding}) block,
	    # we need to go back to a big pageincr (instead of pageincr = 1)
	    if ($page == $self->{padding} || $page == ($self->{cur_page} + $self->{padding})) {
	        $pageincr = POSIX::ceil($self->{pages} / $self->{approx_entries});
	        if ($pageincr < 1) { $pageincr = 1; }
	    }
	    
	    my $next_page = $page + $pageincr;
	    
	    # List the last 10 pages
	    if ($page <= ($self->{cur_page}-10) && $next_page > ($self->{cur_page}-10)) {
	        $next_page = max($self->{cur_page} - $self->{padding}, $page+1);
	        $pageincr = 1;
	    }
	    
	    # List the #{padding} pages before the current page (and we'll go on to get the #{padding} after, too)
	    if ($page <= ($self->{pages} - $self->{padding}) && $next_page > ($self->{pages} - $self->{padding})) {
	        $next_page = max($self->{pages} - $self->{padding}, $page+1);
	        $pageincr = 1;
	    }
	    
	    $page = $next_page;
	}
	
	return @pages;
}

1;
