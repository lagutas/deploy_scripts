#!/usr/bin/perl

use Logic::Tools;
use Cwd;
use DBI();

use strict;

my $path=shift;

my $my_dir = getcwd;
my $tools=Logic::Tools->new(logfile         =>      $my_dir.'/'.$path.'/deploy.log',
                            config_file     =>      '/etc/deploy_scripts/create_linux_users.ini');

my $db_host=$tools->read_config( 'create_linux_users', 'db_host');
my $db=$tools->read_config( 'create_linux_users', 'db');
my $db_user=$tools->read_config( 'create_linux_users', 'db_user');
my $db_password=$tools->read_config( 'create_linux_users', 'db_password');

################### querry for db ##############################
my %query;
$query{'get_linux_users'} = <<EOQ;
SELECT
    u.login, u.secret, sr.rules
FROM
    $db.access_matrix am
    JOIN $db.servers s ON s.id = am.servers_id
    JOIN $db.users u ON u.id = am.users_id
    JOIN $db.sudo_rules sr ON sr.id = am.sudo_rules_id
WHERE
    s.domain = ?;
EOQ

$query{'check_user_exist'} = <<EOQ;
SELECT
    count(*) as num
FROM
    $db.access_matrix am
    JOIN $db.servers s ON s.id = am.servers_id
    JOIN $db.users u ON u.id = am.users_id
    JOIN $db.sudo_rules sr ON sr.id = am.sudo_rules_id
WHERE
    s.domain = ? AND
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

chomp(my $hostname=`sudo hostname`);

$tools->logprint("info","hostname - $hostname");

my $sth=$dbh->prepare($query{'get_linux_users'});

$sth->execute($hostname) or die "Error: query $query{'get_linux_users'} failed: $!";

while (my $user_ref=$sth->fetchrow_hashref())
{
    $tools->logprint("info","create user for hostname - $hostname, login - $user_ref->{'login'}, secret - $user_ref->{'secret'}, sudo_rules - $user_ref->{'rules'}");
    my $result=`useradd -m -s /bin/bash -p $user_ref->{'secret'} $user_ref->{'login'} 1>/dev/null 2>/dev/null; echo "1"`;
    if($result==1)
    {
        $tools->logprint("info","user $user_ref->{'login'} was created");
        my $change_password=`echo "$user_ref->{'login'}:$user_ref->{'secret'}" | chpasswd; echo "1"`;
        if($change_password==1)
        {
            $tools->logprint("info","password for user $user_ref->{'login'} was changed");
            my $sudo_rules=$user_ref->{'rules'};
            $sudo_rules=~s/(\%USERNAME\%)(.+)/$user_ref->{'login'}$2/;
            $tools->logprint("info","sudo_rules - $sudo_rules");
            open(my $sudo_file,">","$user_ref->{'login'}");
            print $sudo_file $sudo_rules."\n";
            close($sudo_file);

            `sudo mv $user_ref->{'login'} /etc/sudoers.d/$user_ref->{'login'}`;
        }
    }
}
$sth->finish();

foreach(split("\n"),`sudo cat /etc/passwd`)
{
    my ($user,$id);
    if($_=~/^(.+):.:(\d+).+$/)
    {
        $user=$1;
        $id=$2;
    }
    
    if($id>1000 && $id<9000)
    {
        my $check_user_exist_sth=$dbh->prepare($query{'check_user_exist'});

        $check_user_exist_sth->execute($hostname,$user);

        my $check_user_exist_ref=$check_user_exist_sth->fetchrow_hashref();

        if($check_user_exist_ref->{'num'}==0)
        {
            my $result=`sudo userdel $user; echo "1"`;
            if($result==1)
            {
                $tools->logprint("info","user $user has been deleted");
            }
        }

        $check_user_exist_sth->finish();
    }
}


$dbh->disconnect();