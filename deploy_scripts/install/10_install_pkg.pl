#!/usr/bin/perl

use Cwd;
use Logic::Tools;
use strict;

my $path=shift;

my $my_dir = getcwd;
my $tools=Logic::Tools->new(#logfile         =>      $my_dir.'/'.$path.'/deploy.log',
                            logfile         =>      'Syslog',
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

    #check DBI package in the current os
    eval { require DBI };
    my $dbi= $@ ? 'No' : 'Yes';

    #install package quiet
    if($dbi eq "No")
    {
        $tools->logprint("info","install perl-DBI");
        `sudo yum -y install perl-DBI`; 
    }

    #check perl-DBD-MySQL package in the current os
    eval { require DBD::MySQL };
    my $dbd_mysql= $@ ? 'No' : 'Yes';

    #install package quiet
    if($dbd_mysql eq "No")
    {
        $tools->logprint("info","install DBD::MySQL");
        `sudo yum -y install perl-DBD-MySQL`; 
    }
    
    $tools->logprint("info","install mutt");
    `sudo yum -y install mutt`; 

    $tools->logprint("info","install ssmtp");
    `sudo yum -y install ssmtp`; 

    #check perl-Test-Strict package in the current os
    eval { require Test::Strict };
    my $test_strict= $@ ? 'No' : 'Yes';

    #install package quiet
    if($test_strict eq "No")
    {
        $tools->logprint("info","install perl-Test-Strict");
        `sudo yum -y install perl-Test-Strict`; 
    }

    #check perl-Test-Fixme package in the current os
    eval { require Test::Fixme };
    my $test_fixme= $@ ? 'No' : 'Yes';

    #install package quiet
    if($test_fixme eq "No")
    {
        $tools->logprint("info","install perl-Test-Fixme");
        `sudo yum -y install perl-Test-Fixme`; 
    }

    #check perl-Test-Perl-Critic package in the current os
    eval { require Test::Perl::Critic };
    my $test_perl_critic= $@ ? 'No' : 'Yes';

    #install package quiet
    if($test_perl_critic eq "No")
    {
        $tools->logprint("info","install perl-Test-Perl-Critic");
        `sudo yum -y install perl-Test-Perl-Critic`; 
    }

    $tools->logprint("info","install ntp");
    `sudo yum -y install ntp`; 
    
    my $ntpd_status=`sudo /etc/init.d/ntpd status`;
    chomp($ntpd_status);
    if($ntpd_status=~/is\srunning/)
    {
        $tools->logprint("info","ntpd is running");
    }
    else
    {
        $tools->logprint("info","try run ntpd");
        `sudo /etc/init.d/ntpd start`;
    }

    #check MySQL-python package exist in system 
    chomp(my $check_mysqldb_modpy=`rpm -qa MySQL-python`);
    unless($check_mysqldb_modpy)
    {
        $tools->logprint("info","sudo yum -y install MySQL-python 1>$path/10_install_pkg.log 2>$path/10_install_pkg.log");
        `sudo yum -y install MySQL-python 1>$path/10_install_pkg.log 2>$path/10_install_pkg.log`
    }

	$tools->logprint("info","install openssh-clients");
    `sudo yum -y install openssh-clients`;     
    
}

if ($pm eq "apt-get")
{
    $tools->logprint("info","debian");
    $tools->logprint("info","apt-get -y -qq update");
    `apt-get -y -qq update`;

    #install mysql-client
    `sudo aptitude -y install mysql-client 1>>$path/10_install_pkg.log 2>>$path/10_install_pkg.log`;

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

    #check Test::Fixme
    eval { require Test::Fixme };
    my $test_fixme= $@ ? 'No' : 'Yes';

    #install package quiet
    if($test_fixme eq "No")
    {
        $tools->logprint("info","sudo apt-get -y install libtest-fixme-perl 1>$path/10_install_pkg.log 2>$path/10_install_pkg.log");
        `sudo apt-get -y install libtest-fixme-perl 1>>$path/10_install_pkg.log 2>>$path/10_install_pkg.log`; 
    }

    #check Test::Perl::Critic
    eval { require Test::Perl::Critic };
    my $test_perl_critic= $@ ? 'No' : 'Yes';

    #install package quiet
    if($test_perl_critic eq "No")
    {
        $tools->logprint("info","sudo apt-get -y install libtest-perl-critic-perl 1>$path/10_install_pkg.log 2>$path/10_install_pkg.log");
        `sudo apt-get -y install libtest-perl-critic-perl 1>>$path/10_install_pkg.log 2>>$path/10_install_pkg.log`; 
    }

    #check Test::Kwalitee
    eval { require Test::Kwalitee };
    my $test_kwalitee= $@ ? 'No' : 'Yes';

    #install package quiet
    if($test_kwalitee eq "No")
    {
        $tools->logprint("info","sudo apt-get -y install libtest-kwalitee-perl 1>$path/10_install_pkg.log 2>$path/10_install_pkg.log");
        `sudo apt-get -y install libtest-kwalitee-perl 1>>$path/10_install_pkg.log 2>>$path/10_install_pkg.log`; 
    }
    
    #check python-mysqldb 
    chomp(my $check_mysqldb_modpy=`dpkg-query -W python-mysqldb 2>/dev/null`);
    unless($check_mysqldb_modpy=~/python-mysqldb/)
    {

        $tools->logprint("info","sudo apt-get -y install python-mysqldb 1>$path/10_install_pkg.log 2>$path/10_install_pkg.log");
        `sudo apt-get -y install python-mysqldb 1>$path/10_install_pkg.log 2>$path/10_install_pkg.log`;
    }
}
