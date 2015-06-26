#!/usr/bin/perl

use Logic::Tools;
use Cwd;

use strict;

my $command=shift;
my $path=shift;


my $my_dir = getcwd;
my $tools=Logic::Tools->new(logfile         =>      $my_dir.'/'.$path.'/deploy.log',
                            logsize         =>      '1Mb',
                            log_num         =>      4);

my $exec_command=$command." 1>/dev/null 2>$path/exec_log.log";

$tools->logprint("info","exec $exec_command");

eval 
{
	`$exec_command`;
};

open(my $exec_log,"<","$path/exec_log.log");

my @exec_log;
while(<$exec_log>)
{
    chomp;
    push(@exec_log,$_);
}

close($exec_log);

