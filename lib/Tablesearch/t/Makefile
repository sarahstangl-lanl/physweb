#
#  ~/myproject/tests/Makefile
#  http://www.debian-administration.org/articles/297
#
#  Run our tests, either quietly or with verbose output
#
all:
	perl -MTest::Harness -e 'use lib "../../"; $$Test::Harness::verbose=0; runtests @ARGV;' *.t
verbose:
	perl -MTest::Harness -e 'use lib "../../"; $$Test::Harness::verbose=1; runtests @ARGV;' *.t
clean:
	find . -name '*~' -exec rm -f \{\} \;
