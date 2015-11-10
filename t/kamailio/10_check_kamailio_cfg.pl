#!/usr/bin/perl

use Logic::Tools;
use Getopt::Long;
use File::stat;
use Cwd;

use strict;

my ($path,$kamailio_path,$emails);
GetOptions( "path=s"            => \$path, 
            "kamailio_path=s"   => \$kamailio_path,
            "emails=s"          => \$emails);


my $my_dir = getcwd;
my $tools=Logic::Tools->new(logfile => 'Syslog');


$tools->logprint("info","kamailio test path - $path, kamailio_path - $kamailio_path, emails - $emails");

#1 - test simple config for sintax -------------------------------------------------------------------
$tools->logprint("info","run: kamailio -f $kamailio_path/kamailio.cfg -c 1>$path/dev/null 2>$path/check_log1");
`kamailio -f $kamailio_path/kamailio.cfg -c 1>/dev/null 2>$path/check_log1`;


open(my $check_log,"<","$path/check_log1");

my $i=0;
while(<$check_log>)
{
    $i++;
    chomp;
    #print "!$_!\n";
    if($_=~/^config\sfile\sok,\sexiting\.\.\.$/)
    {
        #print "OK";
        $i=0;
        last;
    }
}
close($check_log);

#если счетчик итераций больше 0 - значит ошибки в файле есть, выводим их на экран
if($i>0)
{
    open(my $check_log,"<","$path/check_log1");
    my @check_log;
    while(<$check_log>)
    {
        chomp;
        print STDERR "$_\n";
        push(@check_log,$_."\n");
    }
    close($check_log);


    my $command=$path.'/install/mail_send.pl'.
                                ' -emails '.$emails.
                                ' -theme '.'"[kamailio deploy]: simple test, error in the kamailio config"'.
                                ' -path '.$path;
    $tools->logprint("info","exec $command");
    `$command`;

    print "TEST ERROR: @check_log";
}
else
{
    $tools->logprint("info","test 1 OK");
}


close($check_log);

#2 - test kamailio

#get kamailio process
chomp(my $kamailio_ps=`ps ax | grep kamailio`);
my $kamailio_start_command;
foreach(split("\n",$kamailio_ps))
{
    if($_ =~ /.+kamailio.+kamailio\.pid.+/)
    {
        $kamailio_start_command=$_;
        last;
    }
}

$kamailio_start_command=~s/.+\d+\s(\/.+)/$1/;

unlink("$kamailio_path/kamailio_test.cfg");
unlink("/tmp/kamailio_ctl_test");
unlink("/tmp/kamailio_fifo_test");

my $pid;
eval
{
    local $SIG{'ALRM'} = sub { die "timed out\n" };
    alarm(10);
    $pid = fork;

    if ($pid == 0) 
    {
        open(my $kamailio_desc,"<",$kamailio_path."/kamailio.cfg") or print "can't open file $kamailio_path/kamailio.cfg";
        open(my $kamailio_test_desc,">",$kamailio_path."/kamailio_test.cfg") or print "can't open file $kamailio_path/kamailio.cfg";
        while(<$kamailio_desc>)
        {
            if($_=~/^(.+)kamailio_fifo(.+)$/)
            {
                print $kamailio_test_desc $1."kamailio_fifo_test".$2;
            }
            elsif($_=~/^(.+)kamailio_ctl(.+)$/)
            {
                print $kamailio_test_desc $1."kamailio_ctl_test".$2;
            }
            else
            {
                print $kamailio_test_desc $_;
            }
        }
        close($kamailio_desc);
        close($kamailio_test_desc);

        #add debug flag to kamailio start comand
        if(defined($kamailio_start_command))
        {
            $kamailio_start_command=$kamailio_start_command." -f ".$kamailio_path."/kamailio_test.cfg -D -E 1>>$path/check_log2 2>>$path/check_log2";
        }
        else
        {
            $kamailio_start_command="/usr/sbin/kamailio -P /var/run/kamailio.pid -m 256 -M 32 -u kamailio -g kamailio -f ".$kamailio_path."/kamailio_test.cfg -D -E 1>>$path/check_log2 2>>$path/check_log2";
        }
        #print STDERR "$kamailio_start_command"."\n";
        $tools->logprint("info","run: $kamailio_start_command");
        my $kamailio_test=`$kamailio_start_command`;
        print STDERR $kamailio_test if defined($kamailio_test);
    }
    else 
    {
        wait;
    }
    alarm(0);

};
if ($@) 
{
        
    if ($@ eq "timed out\n") 
    {
        #get kamailio debug process
        chomp(my $kamailio_ps=`ps ax | grep 'kamailio_test.cfg -D -E'`);
        foreach(split("\n",$kamailio_ps))
        {
            $_=~s/^\s+(.+)/$1/;
            #print STDERR "!$_!"."\n";
            my $kam_debug_pid;
            if($_ =~/^(\d+)\s.+kamailio.+kamailio\.pid.+$/)
            {
                #print STDERR $1."\n";
                $kam_debug_pid=$1;
            }
            if(defined($kam_debug_pid))
            {
                kill(9,$kam_debug_pid);
            }
        }
        kill(15,$pid);
    }
}

open(my $check_log,"<","$path/check_log2");
my @check_log;
my $i=0;
while(<$check_log>)
{
    chomp;
    if($_=~/ERROR/)
    {
        if($_=~/^.+setting\spvar\sfailed$/)
        {
            $tools->logprint("info","test 2 not critical error");    
        }
        elsif($_=~/^.+assignment\sfailed\sat\spos.+$/)
        {
            $tools->logprint("info","test 2 not critical error");
        }
        elsif($_=~/^.+failed\sto\sparse\suri$/)
        {
            $tools->logprint("info","test 2 not critical error");
        }
        elsif($_=~/^.+no\svalue\sfor\sfirst\sparam$/)
        {
            $tools->logprint("info","test 2 not critical error");
        }
        elsif($_=~/^.+Bad\sfile\sdescriptor.+$/)
        {
            $tools->logprint("info","test 2 not critical error");
        }
        elsif($_=~/^.+sip\sudp_send\sfailed$/)
        {
            $tools->logprint("info","test 2 not critical error");
        }
        elsif($_=~/^.+ruri\scontains\susername$/)
        {
            $tools->logprint("info","test 2 not critical error");
        }
        elsif($_=~/^.+bad\smessage.+$/)
        {
            $tools->logprint("info","test 2 not critical error");
        }
        elsif($_=~/^.+parse_msg.+$/)
        {
            $tools->logprint("info","test 2 not critical error");
        }
        elsif($_=~/^.+core\sparsing\sof\sSIP\smessage\sfailed.+$/)
        {
            $tools->logprint("info","test 2 not critical error");
        }
        elsif($_=~/^.+Socket\soperation\son\snon-socket.+$/)
        {
            $tools->logprint("info","test 2 not critical error");
        }
        elsif($_=~/^.+tcp_send\sfailed.+$/)
        {
            $tools->logprint("info","test 2 not critical error");
        }
        elsif($_=~/^.+Attempt\sto\ssend\sto\sprecreated\srequest\sfailed.+$/)
        {
            $tools->logprint("info","test 2 not critical error");
        }
        elsif($_=~/^.+cannot\sforward\sreply$/)
        {
            $tools->logprint("info","test 2 not critical error");
        }
        elsif($_=~/^.+parse_via.+$/)
        {
            $tools->logprint("info","test 2 not critical error");
        }
        elsif($_=~/^.+get_hdr_field.+$/)
        {
            $tools->logprint("info","test 2 not critical error");
        }
        elsif($_=~/^.+parse_headers.+$/)
        {
            $tools->logprint("info","test 2 not critical error");
        }
        elsif($_=~/^.+update_presentity.+$/)
        {
            $tools->logprint("info","test 2 not critical error");
        }
        elsif($_=~/^.+test_max_contacts.+$/)
        {
            $tools->logprint("info","test 2 not critical error");
        }
        elsif($_=~/^.+uri2dst2.+$/)
        {
            $tools->logprint("info","test 2 not critical error");
        }
        elsif($_=~/^.+t_forward_nonack.+$/)
        {
            $tools->logprint("info","test 2 not critical error");
        }
        elsif($_=~/^.+sl_reply_error.+$/)
        {
            $tools->logprint("info","test 2 not critical error");
        }
        elsif($_=~/^.+t_reply.+$/)
        {
            $tools->logprint("info","test 2 not critical error");
        }
        elsif($_=~/^.+t_send_branch.+$/)
        {
            $tools->logprint("info","test 2 not critical error");
        }
        elsif($_=~/^.+parse_addr_spec.+$/)
        {
            $tools->logprint("info","test 2 not critical error");
        }
        elsif($_=~/^.+pv_get_callid.+$/)
        {
            $tools->logprint("info","test 2 not critical error");
        }
        elsif($_=~/^.+parse_from_header.+$/)
        {
            $tools->logprint("info","test 2 not critical error");
        }
        elsif($_=~/^.+pv_get_from_attr.+$/)
        {
            $tools->logprint("info","test 2 not critical error");
        }
        elsif($_=~/^.+pv_get_to_attr.+$/)
        {
            $tools->logprint("info","test 2 not critical error");
        }
        elsif($_=~/^.+t_check_msg.+$/)
        {
            $tools->logprint("info","test 2 not critical error");
        }
        elsif($_=~/^.+is_maxfwd_present.+$/)
        {
            $tools->logprint("info","test 2 not critical error");
        }
        elsif($_=~/^.+msg_send.+$/)
        {
            $tools->logprint("info","test 2 not critical error");
        }
        elsif($_=~/^.+incomplet\suri.+$/)
        {
            $tools->logprint("info","test 2 not critical error");
        }
        elsif($_=~/^.+parse_first_line.+$/)
        {
            $tools->logprint("info","test 2 not critical error");
        }
        elsif($_=~/^.+handle_publish.+$/)
        {
            $tools->logprint("info","test 2 not critical error");
        }
        elsif($_=~/^.+dlg_onroute.+$/)
        {
            $tools->logprint("info","test 2 not critical error");
        }
        elsif($_=~/^.+contact_parser.+$/)
        {
            $tools->logprint("info","test 2 not critical error");
        }
        elsif($_=~/^.+parse_contact.+$/)
        {
            $tools->logprint("info","test 2 not critical error");
        }
        elsif($_=~/^.+get_contact_uri.+$/)
        {
            $tools->logprint("info","test 2 not critical error");
        }
        elsif($_=~/^.+auth_check_hdr_md5.+$/)
        {
            $tools->logprint("info","test 2 not critical error");
        }
        elsif($_=~/^.+send_prepared_request_impl.+$/)
        {
            $tools->logprint("info","test 2 not critical error");
        }
        elsif($_=~/^.+db_do_delete.+$/)
        {
            $tools->logprint("info","test 2 not critical error");
        }
        elsif($_=~/^.+delete_offline_presentities.+$/)
        {
            $tools->logprint("info","test 2 not critical error");
        }
        elsif($_=~/^.+process_dialogs.+$/)
        {
            $tools->logprint("info","test 2 not critical error");
        }
        elsif($_=~/^.+db_mysql_submit_query.+$/)
        {
            $tools->logprint("info","test 2 not critical error");
        }
        elsif($_=~/^.+parse_from_uri.+$/)
        {
            $tools->logprint("info","test 2 not critical error");
        }
        elsif($_=~/^.+pv_get_xto_attr.+$/)
        {
            $tools->logprint("info","test 2 not critical error");
        }
        elsif($_=~/^.+parse_cseq.+$/)
        {
            $tools->logprint("info","test 2 not critical error");
        }
        elsif($_=~/^.+reply_filter.+$/)
        {
            $tools->logprint("info","test 2 not critical error");
        }
        elsif($_=~/^.+parse_content_length.+$/)
        {
            $tools->logprint("info","test 2 not critical error");
        }
        elsif($_=~/^.+extract_aor.+$/)
        {
            $tools->logprint("info","test 2 not critical error");
        }
        elsif($_=~/^.+registered.+$/)
        {
            $tools->logprint("info","test 2 not critical error");
        }
        elsif($_=~/^.+db_do_query_internal.+$/)
        {
            $tools->logprint("info","test 2 not critical error");
        }
        else
        {
            $i++;
            print "$_\n";
        }
    }
    else
    {
        $tools->logprint("info","test 2 OK");
    }

}
close($check_log);

#unlink core files if exist
my @core_file = glob('core.*');
foreach(@core_file)
{
    unlink $_;
}

if($i>0)
{

    my $command=$path.'/install/mail_send.pl'.
                                ' -emails '.$emails.
                                ' -theme '.'"[kamailio deploy]: error in the kamailio config"'.
                                ' -path '.$path;
    $tools->logprint("info","exec $command");
    `$command`;

    print "ERROR in the kamailio config\n";
}
