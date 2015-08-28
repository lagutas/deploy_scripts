#!/usr/bin/perl

use Logic::Tools;
use Getopt::Long;
use Cwd;

use strict;

my $my_dir = getcwd;


#test_dir - simple test for all scripts
#specific_test_dir - optional path to script specific test
my ($path,$script_name,$src_script_dir,$dst_script_dir,$script_cfg_name,$src_script_cfg_dir,$dst_script_cfg_dir,$test_dir,$specific_test_dir,$emails,$test_only);

GetOptions( "path=s"                => \$path, 
            "script_name=s"         => \$script_name,
            "src_script_dir=s"      => \$src_script_dir,
            "dst_script_dir=s"      => \$dst_script_dir,
            "script_cfg_name=s"     => \$script_cfg_name,
            "src_script_cfg_dir=s"  => \$src_script_cfg_dir,
            "dst_script_cfg_dir=s"  => \$dst_script_cfg_dir,
            "test_dir=s"            => \$test_dir,
            "specific_test_dir=s"   => \$specific_test_dir,
            "emails=s"              => \$emails,
            "test_only=s"           => \$test_only);


#my $tools=Logic::Tools->new(logfile => $my_dir.'/'.$path.'/deploy.log');
my $tools=Logic::Tools->new(logfile => 'Syslog');

$tools->logprint("info","unit test [$script_name]: $script_name");

$tools->logprint("info","unit test [$script_name]: read test dir $test_dir");

opendir(my $test_dir_hdl,$test_dir) || $tools -> logprint("error","unit test [$script_name]:не удалось открыть каталог $test_dir");

my @tests=readdir($test_dir_hdl);

my %tests;
foreach(@tests)
{
    if($_=~/^(\d\d).+t$/)
    {
        $tests{$1}=$_;
    }
}
closedir $test_dir_hdl;

my @test_num;
foreach my $key (keys %tests)
{
    push(@test_num,$key);
}

@test_num = sort { $a <=> $b } @test_num;

#make dir for tests log
mkdir($my_dir.'/'.$src_script_dir.'/testlog');
#execute test in sequence
foreach(@test_num)
{
    my $command='sudo perl '.$my_dir.'/'.$test_dir.'/'.$tests{$_}.' '.$my_dir.'/'.$src_script_dir.'/script'.' 1>>'.$my_dir.'/'.$src_script_dir.'/testlog/'.$tests{$_}.'.log'.' 2>>'.$my_dir.'/'.$src_script_dir.'/testlog/'.$tests{$_}.'.log';
    $tools->logprint("info","unit test [$script_name]: $tests{$_} run $command");
    `$command`;
    my $test_name=$tests{$_};
    open(my $test_log,"<",$my_dir.'/'.$src_script_dir.'/testlog/'.$tests{$_}.'.log');
    my $error_count=0;
    my @message;
    while (<$test_log>) 
    {
        chomp;
        $tools->logprint("info","unit test [$script_name]: $test_name - $_");
        if($_=~/not\sok/||$_=~/Can\'t\slocate/||$_=~/error/||$_=~/FAILED/)
        {
            print $_."\n";
            $tools->logprint("error","unit test [$script_name]: $test_name - $_");
            push(@message,$_);
            $error_count++;
        }
    }
    close($test_log);
    if($error_count>0)
    {
        $tools->logprint("error","unit test [$script_name]: project has many error: $error_count");
        my $command=$path.'/install/mail_send.pl'.
                                ' -emails '.$emails.
                                ' -theme '.'"project has many error: '.$error_count.'"'.
                                ' -message "'.join("\n",@message).'"'.
                                ' -path '.$path;
        $tools->logprint("info","unit test [$script_name]: send mail $command");
        `$command`;
        print -1;
        exit;
    }
}

#------------------------------------------------------------------------------------------------------------------------------------------------------------------

if(defined($specific_test_dir))
{
    $tools->logprint("info","unit test [$script_name]: run script specific tests");

    opendir(my $specific_test_dir_hdl,$specific_test_dir) || $tools -> logprint("error","unit test [$script_name]:не удалось открыть каталог $specific_test_dir");

    my @tests=readdir($specific_test_dir_hdl);

    my %tests;
    foreach(@tests)
    {
        if($_=~/^(\d\d).+t$/)
        {
            $tests{$1}=$_;
        }
    }
    closedir $specific_test_dir_hdl;

    my @test_num;
    foreach my $key (keys %tests)
    {
        push(@test_num,$key);
    }

    @test_num = sort { $a <=> $b } @test_num;

    #make dir for tests log
    mkdir($my_dir.'/'.$src_script_dir.'/testlog');
    #execute test in sequence
    foreach(@test_num)
    {
        my $command='sudo perl '.$my_dir.'/'.$specific_test_dir.'/'.$tests{$_}.' '.$my_dir.'/'.$src_script_dir.'/script'.' 1>>'.$my_dir.'/'.$src_script_dir.'/testlog/'.$tests{$_}.'.log'.' 2>>'.$my_dir.'/'.$src_script_dir.'/testlog/'.$tests{$_}.'.log';
        $tools->logprint("info","unit test [$script_name]: $tests{$_} run $command");
        `$command`;
        my $test_name=$tests{$_};
        open(my $test_log,"<",$my_dir.'/'.$src_script_dir.'/testlog/'.$tests{$_}.'.log');
        my $error_count=0;
        my @message;
        while (<$test_log>) 
        {
            chomp;
            $tools->logprint("info","unit test [$script_name]: $test_name - $_");
            if($_=~/not\sok/||$_=~/Can\'t\slocate/||$_=~/error/||$_=~/FAILED/)
            {
                print $_."\n";
                $tools->logprint("error","unit test [$script_name]: $test_name - $_");
                push(@message,$_);
                $error_count++;
            }
        }
        close($test_log);
        if($error_count>0)
        {
            $tools->logprint("error","unit test [$script_name]: project has many error: $error_count");
            my $command=$path.'/install/mail_send.pl'.
                                    ' -emails '.$emails.
                                    ' -theme '.'"project has many error: '.$error_count.'"'.
                                    ' -message "'.join("\n",@message).'"'.
                                    ' -path '.$path;
            $tools->logprint("info","unit test [$script_name]: send mail $command");
            `$command`;
            print -1;
            exit;
        }
    }
}

if($test_only!=1)
{   
    my $cfg_install=0;
    if(defined($src_script_cfg_dir))
    {
        my $command=$path.'/install/20_install_projects.pl '.$src_script_cfg_dir.'/'.$script_cfg_name.' '.$dst_script_cfg_dir.'/'.$script_cfg_name.' '.$path;
        $tools->logprint("info","unit test [$script_name]: install cfg $command");
        $cfg_install=`$command`; 
        if($cfg_install<0) 
        { 
            $tools->logprint("error","unit test [$script_name]: error install cfg file");
            my $command=$path.'/install/mail_send.pl'.
                                        ' -emails '.$emails.
                                        ' -theme '.'"['.$script_name.']: error install cfg file"'.
                                        ' -path '.$path;
            $tools->logprint("info","unit test [$script_name]: send mail $command");
            `$command`;
            print -1;
            exit;
        }
    }
    

    my $command=$path.'/install/20_install_projects.pl '.$src_script_dir.'/script/'.$script_name.' '.$dst_script_dir.'/'.$script_name.' '.$path;
    $tools->logprint("info","unit test [$script_name]: install $command");
    my $script_install=`$command`; 
    if($script_install<0) 
    { 
        $tools->logprint("error","unit test [$script_name]: error install script");
        my $command=$path.'/install/mail_send.pl'.
                                    ' -emails '.$emails.
                                    ' -theme '.'"['.$script_name.']: error install script"'.
                                    ' -path '.$path;
        $tools->logprint("info","unit test [$script_name]: send mail $command");
        `$command`;
        print -1;
        exit;
    }

    my $command='sudo chmod +x '.$dst_script_dir.'/'.$script_name;
    my $chmod=`$command`; if($chmod ne undef) 
    {
        $tools->logprint("error","unit test [$script_name]: $chmod");
        print -1;
        exit;
    }


    if($cfg_install>0||$script_install>0)
    {
        $tools->logprint("info","unit test [$script_name]: need script restart");
        my $command=$path.'/install/mail_send.pl'.
                                    ' -emails '.$emails.
                                    ' -theme '.'"['.$script_name.']: need script restart"'.
                                    ' -path '.$path;
        $tools->logprint("info","unit test [$script_name]: send mail $command");
        `$command`;
        print 1;
    }
    else
    {
        $tools->logprint("info","unit test [$script_name]: not need script restart");
        print 0;
    }
}

