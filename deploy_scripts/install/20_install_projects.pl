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

my $result=0;

my $my_dir = getcwd;
my $tools=Logic::Tools->new(logfile => $my_dir.'/'.$path.'/deploy.log');

my $dst_path=$dst_file;

$tools->logprint("info","20_install_project $src_file -> $dst_file");

$dst_path=~s/^(.+)\/.+$/$1/;

if (! -d $dst_path)
{  
  $tools->logprint("info","dir not created, create it");
  eval 
  {
    mkpath($dst_path)
  };
  if ($@) 
  {
    $tools->logprint("info","Failed to create $dst_path: $@\n");
    print -1;
    exit;
  }
}

#get diff between config files
unless ( -e "$dst_file" ) 
{
  $tools->logprint("info","$dst_file not exist, copy new file");
  copy $src_file,$dst_file or eval { $tools->logprint("error","error $src_file -> $dst_file $!"); print -1;};
  print 1;
}


my $diff = diff $src_file, $dst_file;


#install new version of file
if($diff ne undef)
{
    unlink($dst_file);
    copy $src_file,$dst_file or eval { $tools->logprint("error","error $src_file -> $dst_file $!"); print -1;};
    $tools->logprint("info","update $dst_file");
    print 1;
}
else
{
    $tools->logprint("info","20_install_project not need $src_file -> $dst_file");
    print 0;
}
