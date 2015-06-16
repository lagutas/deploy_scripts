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

$tools->logprint("15_vz_create","check vz $ctid");
my @vz_list=split("\n",`vzlist $ctid 2>/dev/null`);
my $ctid_ret=0;
if (defined($vz_list[1]))
{
    $ctid_ret=$vz_list[1];  
    $ctid_ret=~s/^\s+(\d+)\s.+/$1/;
}

$tools->logprint("15_vz_create","$ctid_ret != $ctid");


if($ctid_ret != $ctid)
{
    $tools->logprint("15_vz_create","vz $ctid not created, create id");
    my $vz_create="vzctl create $ctid --ostemplate debian-8.0-x86_64-itlogic --layout ploop";
    $tools->logprint("15_vz_create","$vz_create 1>/dev/null 2> $path/15_vz_create.log");
    `$vz_create 1>/dev/null 2> $path/15_vz_create.log`;
    open(my $vz_log,"<","$path/15_vz_create.log");
    while (<$vz_log>) 
    {
        chomp;
        if($_=~/failed/)
        {
            $tools->logprint("15_vz_create","$_");
        }
    }
    close $vz_log;
}
else
{
    $tools->logprint("15_vz_create","vz $ctid extis");
}

unlink "$path/15_vz_create.log";