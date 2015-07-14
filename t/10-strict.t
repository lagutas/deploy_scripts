use strict;
use warnings;

my $path=shift;

use Test::Strict;

all_perl_files_ok($path); # Syntax ok and use strict;