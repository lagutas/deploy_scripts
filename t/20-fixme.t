use strict;
use warnings;

my $path=shift;

use Test::Fixme;

run_tests(
where => [$path], # where to find files to check
match => qr/FIXME/, # what to check for
);