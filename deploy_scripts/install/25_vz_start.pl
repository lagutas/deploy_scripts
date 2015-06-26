#!/usr/bin/perl

use Logic::Tools;
use Cwd;

use strict;

my $ctid=shift;
my $path=shift;

if(!defined($ctid))
{
    print "ERROR ctid not set\n";
    exit;
}


my $my_dir = getcwd;
my $tools=Logic::Tools->new(logfile         =>      $my_dir.'/'.$path.'/deploy.log',
                            logsize         =>      '1Mb',
                            log_num         =>      4);

while (1) 
{
    $tools->logprint("info","check vz $ctid");
    my @vz_list=split("\n",`vzlist $ctid 2>/dev/null`);
    my $ctid_ret=0;
    if (defined($vz_list[1]))
    {
        $ctid_ret=$vz_list[1];  
        $ctid_ret=~s/^\s+\d+\s+.+\s(\w+)\s+.+/$1/;
    }

    $tools->logprint("info","!$ctid - $ctid_ret!");

    if($ctid_ret eq "stopped")
    {
        my $vz_start="vzctl start $ctid  1>/dev/null 2> $path/25_vz_start.log";
        $tools->logprint("info","$vz_start");
        `$vz_start`;
        open(my $vz_start,"<","$path/25_vz_start.log");
        while (<$vz_start>) 
        {
            chomp;
            if($_=~/failed/||$_=~/error/||$_=~/ERROR/)
            {
                $tools->logprint("info","$_");
                print "$_";
            }
        }
        close $vz_start;
    }
    else
    {
        $tools->logprint("info","$ctid already started");
        exit;
    }
    sleep(1);
}


unlink "$path/25_vz_start.log";