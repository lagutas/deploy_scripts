#!/usr/bin/perl

use Logic::Tools;
use Getopt::Long;
use Cwd;

use strict;

my $my_dir = getcwd;



my ($emails,$theme,$message,$path);
$message=undef;

GetOptions( "emails=s"   => \$emails, 
            "theme=s"    => \$theme,
            "message=s"  => \$message,
            "path=s"     => \$path);


#my $tools=Logic::Tools->new(logfile => $my_dir.'/'.$path.'/deploy.log');
my $tools=Logic::Tools->new(logfile => 'Syslog');

$tools->logprint("info","send mail: $emails: [$theme] $message");

chomp(my $hostname=`hostname -f`);

chomp(my $check_mutt=`whereis -b mutt | grep ": /" | wc -l`);
    
my $mail_sender;
if($check_mutt==1)
{
    $mail_sender='mutt';
}
else
{
    $mail_sender='mail';   
}

if(defined($emails))
{
    foreach(split(",",$emails))
    {        
        `echo "$message" | $mail_sender -s "$hostname: $theme" $_`;
    }
}
else
{
    `echo "$message" | $mail_sender -s "$hostname:INFO $theme" root`;
}