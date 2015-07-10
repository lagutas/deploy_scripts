#!/usr/bin/perl

use strict;

use Text::Diff;
use File::Copy;
use File::Path;
use Logic::Tools;
use Cwd;

#parameters 2 file
my $src_file = shift;
my $dst_file = shift;
my $path = shift;

my $result;

my $my_dir = getcwd;
my $tools=Logic::Tools->new(logfile         =>      $my_dir.'/'.$path.'/deploy.log',
                            logsize         =>      '1Mb',
                            log_num         =>      4);

my $dst_path=$dst_file;

$dst_path=~s/^(.+)\/.+$/$1/;

if (! -d $dst_path)
{
  my $dirs = eval { mkpath($dst_path) };
  print "Failed to create $dst_path: $@\n" unless $dirs;
}

#get diff between config files
unless ( -e "$dst_file" ) 
{
	$tools->logprint("info","$dst_file not exist, copy new file");
    copy $src_file,$dst_file or print "ERROR copying file $src_file -> $dst_file";
    $result=1;
}


my $diff = diff $src_file, $dst_file;


#install new version of file
if($diff ne undef)
{
    unlink($dst_file);
    copy $src_file,$dst_file or print "ERROR copying file $src_file -> $dst_file";
    $tools->logprint("info","update $dst_file");
    $result=1;
}


return $result;
