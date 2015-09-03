#!/usr/bin/perl

use Getopt::Long;
use Logic::Tools;
use Cwd;
use strict;

my ($path,$emails);
GetOptions( "path=s"            => \$path,
            "emails=s"          => \$emails);

my $my_dir = getcwd;
my $tools=Logic::Tools->new(logfile => 'Syslog');


my $kamailio_pid_file;
my $pid;
if( -e "/var/run/kamailio.pid")
{
	$kamailio_pid_file = "/var/run/kamailio.pid";
}
elsif( -e "/var/run/kamailio/kamailio.pid")
{
	$kamailio_pid_file = "/var/run/kamailio/kamailio.pid";
}



open(my $pid_file,'<',$kamailio_pid_file) || die "ERROR: can't open file";
my $pid=<$pid_file>;
close $pid_file;
chomp $pid;
        
unless( -e "/proc/$pid" )
{
    send_error($emails,"kamailio not run");
    my $command=$path.'/install/mail_send.pl'.
                                ' -emails '.$emails.
                                ' -theme '.'"[kamailio deploy]: test after reboot"'.
                                ' -path '.$path.
                                ' -message '.'error: kamailio not run';
    $tools->logprint("info","exec $command");
    `$command`;
}

my $ctl_error;
unless( -e "/tmp/kamailio_ctl" )
{
    my $command=$path.'/install/mail_send.pl'.
                                ' -emails '.$emails.
                                ' -theme '.'"[kamailio deploy]: test after reboot"'.
                                ' -path '.$path.
                                ' -message '.'"/tmp/kamailio_ctl not exist"';
    $tools->logprint("info","exec $command");
    `$command`;
    if($ctl_error!=2)
    {
        $ctl_error=1;
        print "error: /tmp/kamailio_ctl not exist\n";    
    }
}

my $fifo_error;
unless( -e "/tmp/kamailio_fifo" || -e "/var/run/kamailio/kamailio_fifo")
{
    my $command=$path.'/install/mail_send.pl'.
                                ' -emails '.$emails.
                                ' -theme '.'"[kamailio deploy]: test after reboot"'.
                                ' -path '.$path.
                                ' -message '.'"kamailio_fifo not exist"';
    $tools->logprint("info","exec $command");
    `$command`;
    if($fifo_error!=2)
    {
        $fifo_error=1;
        print "error: kamailio_fifo not exist\n";
    }
}

if($ctl_error==1)
{
    sleep(3);
    my $command=$path.'/install/mail_send.pl'.
                                ' -emails '.$emails.
                                ' -theme '.'"[kamailio deploy]: test after reboot"'.
                                ' -path '.$path.
                                ' -message '.'"ctl not be created, need restart again"';
    $tools->logprint("info","exec $command");
    `$command`;
    $ctl_error=2;
}

if($fifo_error==1)
{
    sleep(3);
    my $command=$path.'/install/mail_send.pl'.
                                ' -emails '.$emails.
                                ' -theme '.'"[kamailio deploy]: test after reboot"'.
                                ' -path '.$path.
                                ' -message '.'"fifo not be created, need restart again"';
    $tools->logprint("info","exec $command");
    `$command`;
    $fifo_error=2;
}
