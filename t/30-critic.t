use strict;
use warnings;

my $path=shift;

use Test::Perl::Critic;

all_critic_ok($path);
