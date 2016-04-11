#!/usr/bin/perl -w

use Logic::Tools;
use Cwd;
use DBI();

use strict;

my $path=shift;
my $dir=shift;

my $my_dir = getcwd;
my $tools=Logic::Tools->new(logfile         =>      'Syslog',
                            config_file     =>      '/etc/deploy_scripts/create_linux_users.ini');

my $db_host     = $tools->read_config( 'create_linux_users', 'db_host');
my $db          = $tools->read_config( 'create_linux_users', 'db');
my $db_user     = $tools->read_config( 'create_linux_users', 'db_user');
my $db_password = $tools->read_config( 'create_linux_users', 'db_password');

################### querry for db ##############################
my %query;
$query{'get_linux_users'} = <<EOQ;
SELECT
    u.login, u.secret
FROM
    $db.service_access_matrix sam
    JOIN $db.services s ON s.id = sam.services_id
    JOIN $db.users u ON u.id = sam.users_id
	JOIN $db.servers ser ON ser.id = sam.servers_id
	WHERE ser.domain = ?;
EOQ

$query{'check_user_exist'} = <<EOQ;
SELECT
    count(*) as num
FROM
    $db.service_access_matrix sam
    JOIN $db.services s ON s.id = sam.services_id
    JOIN $db.users u ON u.id = sam.users_id
	JOIN $db.servers ser ON ser.id = sam.servers_id
	WHERE ser.domain = ?
AND
    u.login =?;
EOQ

my $dbh;
eval 
{
    $dbh=DBI->connect("DBI:mysql:$db;host=$db_host",$db_user,$db_password);
};
if ($@) 
{
    die "Error: can't connect to $db $db_host $db_user $@\n";
}
$dbh->{mysql_auto_reconnect} = 1;

chomp(my $hostname=`sudo hostname -f`);

$tools->logprint("info","hostname - $hostname");

my $sth=$dbh->prepare($query{'get_linux_users'});

$sth->execute($hostname) or die "Error: query $query{'get_linux_users'} failed: $!";

`sudo touch $dir/.htpasswd`;

while (my $user_ref=$sth->fetchrow_hashref())
{
    $tools->logprint("info","create user for hostname - $hostname, login - $user_ref->{'login'}, secret - $user_ref->{'secret'}");
    my $result=`sudo htpasswd -b $dir/.htpasswd $user_ref->{'login'} $user_ref->{'secret'} 1>/dev/null 2>/dev/null; echo "1"`;
    if($result==1)
    {
        $tools->logprint("info","user $user_ref->{'login'} was created");
    }
}

$sth->finish();

foreach(split("\n"),`sudo cat $dir/.htpasswd`)
{
    my ($user);
    if($_=~/^(.+):.+$/)
    {
        $user=$1;
    }    
    my $check_user_exist_sth=$dbh->prepare($query{'check_user_exist'});

    $check_user_exist_sth->execute($hostname,$user);

    my $check_user_exist_ref=$check_user_exist_sth->fetchrow_hashref();

    if($check_user_exist_ref->{'num'}==0)
    {
        my $result=`sudo htpasswd -D $dir/.htpasswd $user; echo "1"`;
        if($result==1)
        {
            $tools->logprint("info","user $user has been deleted");
        }
    }

    $check_user_exist_sth->finish();
}

$dbh->disconnect();
