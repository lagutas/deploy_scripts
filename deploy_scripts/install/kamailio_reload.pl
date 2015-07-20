#!/usr/bin/perl

use strict;

use Logic::Tools;
use Getopt::Long;
use File::stat;
use Cwd;

my ($path,$kamailio_path,$emails);

GetOptions( "path=s"            => \$path, 
            "kamailio_path=s"   => \$kamailio_path,
            "emails=s"          => \$emails);


my $my_dir = getcwd;
my $tools=Logic::Tools->new(logfile => $my_dir.'/'.$path.'/deploy.log');


$tools->logprint("info","kamailio reload path - $path, kamailio_path - $kamailio_path, emails - $emails");



#start kamailio if not started
`var=\$(sudo netstat -anlp | grep :5060 | wc -l); if [ \$var -ne 1 ]; then sudo /etc/init.d/kamailio start 1>/dev/null 2>/dev/null; fi`;

my $uptime_before=get_kamailio_uptime();

#check each config file, if at least one older than uptime restart
my $need_restart;

my @config_files=glob('/etc/kamailio/config/*.cfg');
push(@config_files,"/etc/kamailio/kamailio.cfg");

foreach(@config_files)
{
    #print STDERR "1 - ".$_."\n";
    my $statfile = stat("$_");
    my $sec_after_modify;
    if(defined($statfile))
    {
        $sec_after_modify = time() - $statfile->mtime;
    }
    if($sec_after_modify<$uptime_before)
    {
        #print STDERR "2 - $_ \n";
        $need_restart=1;
        last;
    }
}




if(!defined($need_restart))
{
    my $command=$path.'/install/mail_send.pl'.
                                ' -emails '.$emails.
                                ' -theme '.'"[kamailio deploy] kamailio config oldest by kamailio uptime, restart not need"'.
                                ' -path '.$path;
    $tools->logprint("info","exec $command");
    `$command`;
    exit;
}
else
{
    #print STDERR "надо\n";
    #kill all kamailio process
    `killall -9 kamailio 1>/dev/null 2>/dev/null`;

    sleep(5);

    unlink("/var/run/kamailio/kamailio_fifo");
    unlink("/var/run/kamailio/kamailio_ctl");




    #if uptime undef - kamailio was stopped, run it again
    my $uptime=get_kamailio_uptime();
    if($uptime eq undef)
    {
        `/etc/init.d/kamailio start`;
        sleep(5);
    }


    my $uptime_after=get_kamailio_uptime();


    #if uptime after restart > uptime before restart - ERROR

    #print STDERR "после - $uptime_after до - $uptime_before\n";

    if($uptime_after>$uptime_before)
    {
        my $command=$path.'/install/mail_send.pl'.
                                ' -emails '.$emails.
                                ' -theme '.'"[kamailio deploy]: kamailio not be restarting"'.
                                ' -path '.$path;
        $tools->logprint("info","exec $command");
        `$command`;
        print "ERROR ! kamailio not be restarting";
        exit;
    }

    my $command=$path.'/install/mail_send.pl'.
                                ' -emails '.$emails.
                                ' -theme '.'"[kamailio deploy]: new configuration was deployed"'.
                                ' -path '.$path;
    $tools->logprint("info","exec $command");
    `$command`;
}

sub get_kamailio_uptime
{
    my $monitor=`kamctl monitor 1`;
    my $uptime;
    foreach(split("\n",$monitor))
    {
        chomp;
        if($_=~/^Up\stime::\s(\d+)\s\[sec\]$/)
        {
            $uptime=$1;
            last;
        }
    }
    return $uptime;
}