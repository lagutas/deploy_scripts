#!/usr/bin/perl

use File::Path;
use Logic::Tools;
use Cwd qw(abs_path getcwd);
use strict;

my $path=shift;

my $my_dir = getcwd;
my $tools=Logic::Tools->new(logfile         =>      $my_dir.'/'.$path.'/deploy.log',
                            logsize         =>      '1Mb',
                            log_num         =>      4);


(my $abs_path) = abs_path($0) =~ /(.*[\/\\])/;

$abs_path=~s/^(.+)\/\d+\/install\/$/$1/;

$tools->logprint("info","try clean $abs_path");

opendir(my $dir,"$abs_path");
my @dirs=readdir($dir);
closedir $dir;


my @dirs=sort { $b <=> $a } @dirs;

while (scalar(@dirs)>10) 
{   
    my $dir=pop @dirs;
    if($dir=~/\d+/)
    {
    	$tools->logprint("info","delete $abs_path/$dir");
        rmtree("$abs_path/$dir") or print "can't delete $abs_path/$dir\n";
    }
}