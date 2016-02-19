#!/usr/bin/perl -w

use Logic::Tools;
use Cwd;
use DBI();

use strict;

my $my_dir = getcwd;
my $tools=Logic::Tools->new(logfile         =>      'Syslog',
                            config_file     =>      '/etc/deploy_scripts/create_linux_users.ini');

my $db_host1=$tools->read_config( 'create_linux_users', 'db_host');
my $db1=$tools->read_config( 'create_linux_users', 'db');
my $db_user=$tools->read_config( 'create_linux_users', 'db_user');
my $db_password=$tools->read_config( 'create_linux_users', 'db_password');

my $db_host2=$tools->read_config( 'create_monast_users', 'db_host');
my $db2=$tools->read_config( 'create_monast_users', 'db');

################### querry for db ##############################
my %query;
$query{'get_linux_users'} = <<EOQ;
SELECT
    u.login, u.secret, sr.rules
FROM
    $db1.services_access_matrix sam
    JOIN $db1.services s ON s.id = sam.services_id
    JOIN $db1.users u ON u.id = sam.users_id
EOQ

$query{'get_server_id'} = "SELECT id FROM monast_servers;";

$query{'get_task_id'} = "SELECT id FROM tasks WHERE task_name='monast_cfg';";

$query{'add_monast_users'} = "INSERT INTO monast_users VALUES (?,?,'originate,queue,command,spy',?);";

$query{'create_monast_conf'} = "insert into task_queue values(NULL,?,'now',Now(),?);";

my $dbh;
eval 
{
    $dbh=DBI->connect("DBI:mysql:$db1;host=$db_host1",$db_user,$db_password);
};
if ($@) 
{
    die "Error: can't connect to $db1 $db_host1 $db_user $@\n";
}
$dbh->{mysql_auto_reconnect} = 1;

chomp(my $hostname=`sudo hostname`);
$tools->logprint("info","hostname - $hostname");

my $sth=$dbh->prepare($query{'get_linux_users'});
$sth->execute() or die "Error: query $query{'get_linux_users'} failed: $!";

my %user_hash;
while(my $user_ref=$sth->fetchrow_hashref()) {
    my $key = $user_ref->{'login'};
    $user_hash{$key} = $user_ref->{'secret'};
}

$sth->finish();
$dbh->disconnect();

eval 
{
    $dbh=DBI->connect("DBI:mysql:$db2;host=$db_host2",$db_user,$db_password);
};
if ($@) 
{
    die "Error: can't connect to $db2 $db_host2 $db_user $@\n";
}
$dbh->{mysql_auto_reconnect} = 1;

my $sth=$dbh->prepare($query{'get_server_id'});
$sth->execute() or die "Error: query $query{'get_server_id'} failed: $!";
my $ref=$sth->fetchrow_arrayref();
my $server_id = $$ref[0];
$sth->finish();

my $sth=$dbh->prepare($query{'get_task_id'});
$sth->execute() or die "Error: query $query{'get_task_id'} failed: $!";
my $ref=$sth->fetchrow_arrayref();
my $task_id = $$ref[0];
$sth->finish();

foreach my $key (keys %user_hash) 
{
    my $sth=$dbh->prepare($query{'add_monast_users'});
    $sth->execute($key,$user_hash{$key},$server_id);
}

my $sth=$dbh->prepare($query{'create_monast_conf'});
my $q = $sth->execute($task_id,$server_id) or die "Error: query $query{'create_monast_conf'} failed: $!";

$sth->finish();
$dbh->disconnect();




