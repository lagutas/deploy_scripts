#!/usr/bin/perl

use Cwd;
use Logic::Tools;
use strict;

my $path=shift;

my $my_dir = getcwd;
my $tools=Logic::Tools->new(logfile         =>      $my_dir.'/'.$path.'/deploy.log',
                            logsize         =>      '1Mb',
                            log_num         =>      4);


#get linux distribution
my $pm;



if ($^O eq "linux") 
{
    do
    {
    	my $path=`type  $_ 2>/dev/null | tr -d "\n"`;
    	if($path=~/^(.+)\sis\s(.+)$/)
    	{
    	    $pm=$1;
                if (-x $2)
                {
                    last;
                }
    	}
    } for qw/apt-get aptitude yum emerge pacman urpmi zypper/;
}

if ($pm eq "yum")
{
    $tools->logprint("info","centos");
    #check Text::Diff package in the current os
    eval { require Text::Diff };
    my $text_diff= $@ ? 'No' : 'Yes';

    #install package quiet
    if($text_diff eq "No")
    {
        $tools->logprint("info","install perl-Text-Diff");
        `sudo yum -y install perl-Text-Diff`; 
    }
}

if ($pm eq "apt-get")
{
    $tools->logprint("info","debian");
    $tools->logprint("info","apt-get -y -qq update");
    `apt-get -y -qq update`;

    #check Text::Diff package in the current os
    eval { require Text::Diff };
    my $text_diff= $@ ? 'No' : 'Yes';

    #install package quiet
    if($text_diff eq "No")
    {
        $tools->logprint("info","sudo apt-get -y install libtext-diff-perl 1>>$path/10_install_pkg.log 2>>$path/10_install_pkg.log");
        `sudo apt-get -y install libtext-diff-perl 1>>$path/10_install_pkg.log 2>>$path/10_install_pkg.log`; 
    }

    #check Logic::Tools package in the current os
    eval { require Logic::Tools };
    my $logic_tools= $@ ? 'No' : 'Yes';

    #install package quiet
    if($logic_tools eq "No")
    {
        $tools->logprint("info","sudo apt-get -y install liblogic-tools-perl 1>$path/10_install_pkg.log 2>$path/10_install_pkg.log");
        `sudo apt-get -y install liblogic-tools-perl 1>>$path/10_install_pkg.log 2>>$path/10_install_pkg.log`; 
    }

    #check Config::IniFiles
    eval { require Config::IniFiles };
    my $config_inifiles= $@ ? 'No' : 'Yes';

    #install package quiet
    if($config_inifiles eq "No")
    {
        $tools->logprint("info","sudo apt-get -y install libconfig-inifiles-perl 1>$path/10_install_pkg.log 2>$path/10_install_pkg.log");
        `sudo apt-get -y install libconfig-inifiles-perl 1>>$path/10_install_pkg.log 2>>$path/10_install_pkg.log`; 
    }

    #check Config::IniFiles
    eval { require DBI };
    my $dbi= $@ ? 'No' : 'Yes';

    #install package quiet
    if($dbi eq "No")
    {
        $tools->logprint("info","sudo apt-get -y install libdbi-perl 1>$path/10_install_pkg.log 2>$path/10_install_pkg.log");
        `sudo apt-get -y install libdbi-perl 1>>$path/10_install_pkg.log 2>>$path/10_install_pkg.log`; 
    }

    #check Test::Strict
    eval { require Test::Strict };
    my $test_strict= $@ ? 'No' : 'Yes';

    #install package quiet
    if($test_strict eq "No")
    {
        $tools->logprint("info","sudo apt-get -y install libtest-strict-perl 1>$path/10_install_pkg.log 2>$path/10_install_pkg.log");
        `sudo apt-get -y install libtest-strict-perl 1>>$path/10_install_pkg.log 2>>$path/10_install_pkg.log`; 
    }
}
