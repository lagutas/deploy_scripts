#!/usr/bin/perl

use strict;
use Logic::Tools;

my $path=shift;


my $tools=Logic::Tools->new(logfile => 'Syslog');

$tools->logprint("info","start nginx deploy");

chomp(my $check_nginx=`sudo dpkg-query -W nginx 2>/dev/null`);
$tools->logprint("info","check nginx $check_nginx");

unless($check_nginx=~/nginx/)
{
    my $command='sudo aptitude -y install nginx';
    my $exec_command=`$path/install/30_exec_command.pl '$command' $path`; if($exec_command ne undef) {  die $exec_command."\n"; }
}
else
{
    $tools->logprint("info","nginx is already installed");
}

my $check;
my $copy_nginx_config=`$path/install/20_install_projects.pl $path/etc/nginx/nginx.conf /etc/nginx/nginx.conf $path`; if($copy_nginx_config<0) {  die "error install file\n"; exit; }
$check=$copy_nginx_config;

opendir(my $nginx_conf,$path.'/etc/nginx/conf.d/') || $tools -> logprint("error","не удалось открыть каталог $path/etc/nginx/conf.d");
    
my @nginx_conf = readdir($nginx_conf);

foreach my $conf (@nginx_conf) 
{
    my $copy_nginx_config=`$path/install/20_install_projects.pl $path/etc/nginx/conf.d/$conf /etc/nginx/conf.d/$conf $path`; if($copy_nginx_config<0) {  die "error install file\n"; exit; }
    $check=$check+$copy_nginx_config;
}

closedir $nginx_conf;

if($check>0) {
    my $command='sudo /etc/init.d/nginx reload';
    my $exec_command=`$path/install/30_exec_command.pl '$command' $path`; if($exec_command ne undef) {  die $exec_command."\n"; }
}




