#!/usr/bin/perl -w
$|++;
#
# NEW: Calc. local correlation pairwise
# Note: the script was tested and run on
# linux (Ubuntu, 18.04.2 LTS (Bionic Beaver), 4.15.0-43-generic) using
# perl 5, version 26, subversion 1 (v5.26.1) built for x86_64-linux-gnu-thread-multi
#
# author: Mate Nagy
# 
# to use: *.plx (input_files_DIRECTORY)
use strict;
use warnings;

my $INdatadir = shift @ARGV;
my $line="";
my @datFiles = ();

# Check all datafiles in the INdatadir directory

opendir (directory_handle, $INdatadir) or die "Unable to open directory: $!";
while (my $file_name = readdir(directory_handle)) {
    if (length($file_name) >2) {
	push @datFiles, $file_name;
    }
}

unless(-e "OUT/".$INdatadir or mkdir "OUT/".$INdatadir) {
    die "Unable to create OUT/$INdatadir";
}

unless(-e "OUTmax/".$INdatadir or mkdir "OUTmax/".$INdatadir) {
    die "Unable to create OUT/$INdatadir";
}

# Run the calc_localcorr.plx calculation only for a pair

for(my $f1=0; $f1<=$#datFiles; $f1++){
    print "# $datFiles[$f1]\n";
    `nohup nice -n 10 ./a.out $INdatadir/$datFiles[$f1] OUT/$INdatadir/$datFiles[$f1] OUTmax/$INdatadir/$datFiles[$f1]`;
 
}

