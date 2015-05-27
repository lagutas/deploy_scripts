#!/usr/bin/perl

use File::Copy;

use strict;

my $file = shift;
my $keyword = shift;
my $add_string = shift;

open(file_r,"<",$file);
open(file_wr,">",$file."_tmp");

while(<file_r>)
{
    if($_=~/###\sEND\sINIT\sINFO/)
    {
        print file_wr $_."#delpoy already modified\n";
    }
    elsif($_=~$keyword)
    {
        print file_wr $_;
        
        foreach(split(/;/,$add_string))
        {
            #print "-- $_\n";
            print file_wr "$_\n";
        }
    
    }
    elsif($_=~/#delpoy already modified/)
    {
        exit;
    }
    else
    {
        print file_wr $_;
    }
}

close(file_r);
close(file_wr);

copy $file."_tmp",$file or print "ERROR copying file";

unlink $file."_tmp";