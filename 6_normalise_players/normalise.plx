#!/usr/bin/perl -w
$|++;
#
# from the player data normilise results based on the time play together
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
my $OUTdatadir = "PlayerNorm";
my $line="";
my @datFiles = ();

my $ball="Ball";

my $deltaT=4; #### in centisecs! !!!!!!!!!!!

# Check all datafiles in the INdatadir directory

opendir (directory_handle, $INdatadir) or die "Unable to open directory: $!";
while (my $file_name = readdir(directory_handle)) {
    #if ($file_name =~ /txt$/) 
    if (length($file_name)>2 ) {
	push @datFiles, $file_name;
    }
}


foreach my $datFile (@datFiles){
    my $matchName;
    my $p1="";
    my $inputFile=$INdatadir."/".$datFile;
    open(IN, "<$inputFile") || die ("Error: cannot read from $inputFile\n");
    
    my $outputFile="PlayerNorm/".$datFile."_Norm";
    open(OUT, ">$outputFile") || die ("Error: cannot write to $outputFile, make directory: OUT\n");

    my $outputFile2="Team/Team".$datFile;
    open(OUT2, ">$outputFile2") || die ("Error: cannot write to $outputFile2, make directory: OUT\n");
    
    my $outputFile2n="TeamNorm/Team".$datFile."_Norm";
    open(OUT2n, ">$outputFile2n") || die ("Error: cannot write to $outputFile2n, make directory: OUT\n");

    my %HCS_half_p1_best_posses=();
    my %Time_half_p1=();
    my %players=();
    my %teams=();

    my $dataNum=0;
    while($line=<IN>){
	# skip comment lines and empty lines
	if(($line!~/^\s*\#/)&&($line!~/^\s*$/)){
	    chomp $line;
	    my @p = split (' ', $line);
	    $matchName = $p[0];
	    $p1=$p[1];
	    my @p2 = split ('_', $p[1]);
	    my $team = $p2[0];
	    my $colnum=2;
	    
	    for(my $half=0; $half<=2; $half++){
	     for(my $posses=0; $posses<=2; $posses++){
	      for(my $best=0; $best<=1; $best++){
	        # player
    		$HCS_half_p1_best_posses{$half."__".$p1."__".$best."__".$posses} = $p[$colnum];
    		# team
    		if(not defined $HCS_half_p1_best_posses{$half."__".$team."__".$best."__".$posses}){
    		    $HCS_half_p1_best_posses{$half."__".$team."__".$best."__".$posses} = $p[$colnum];
    		} else {
    		    $HCS_half_p1_best_posses{$half."__".$team."__".$best."__".$posses} += $p[$colnum];
    		}
    		$colnum++;
    	     }}
    	        # player
    		$Time_half_p1{$half."__".$p1} = $p[$colnum];
    		# team
    		if(not defined $Time_half_p1{$half."__".$team}){
    		    $Time_half_p1{$half."__".$team} = $p[$colnum];
    		} else {
    		    $Time_half_p1{$half."__".$team} += $p[$colnum];
    		}
    		$colnum++;
    	    }
    	    $dataNum++;
	    
	    if(not defined $players{$p1}){
		$players{$p1}=1;
	    }
	    if(not defined $teams{$team}){
		$teams{$team}=1;
	    }

	} else {
	    #### Print comment lines
	    print OUT $line;
	    print OUT2 $line;
	    print OUT2n $line;
	}
    }

    #### Print out normalised player data
    foreach my $p1 (sort keys %players){
	print OUT $matchName."\t".$p1."\t";
	    for(my $half=0; $half<=2; $half++){
	     for(my $posses=0; $posses<=2; $posses++){
	      for(my $best=0; $best<=1; $best++){
    		if($HCS_half_p1_best_posses{$half."__".$p1."__".$best."__".$posses}!=0){
    		    printf OUT "%.4f\t", (($HCS_half_p1_best_posses{$half."__".$p1."__".$best."__".$posses}*$deltaT)/$Time_half_p1{$half."__".$p1});	# relative in percent!!!!
    	        } else {
    	    	    print OUT "0\t";
    	        }
    	     }}
    		print OUT $Time_half_p1{$half."__".$p1}."\t";
    	    }
	print OUT "\n";
    }
    close(OUT);
    
    #### Print out team data
    foreach my $team (sort keys %teams){
	print OUT2 $matchName."\t".$team."\t";
	print OUT2n $matchName."\t".$team."\t";
	    for(my $half=0; $half<=2; $half++){
	     for(my $posses=0; $posses<=2; $posses++){
	      for(my $best=0; $best<=1; $best++){
    		if($HCS_half_p1_best_posses{$half."__".$team."__".$best."__".$posses}!=0){
    		    printf OUT2 $HCS_half_p1_best_posses{$half."__".$team."__".$best."__".$posses}."\t";
    		    printf OUT2n "%.4f\t", (($HCS_half_p1_best_posses{$half."__".$team."__".$best."__".$posses}*$deltaT)/$Time_half_p1{$half."__".$team});	# relative in percent!!!!
    	        } else {
    	    	    print OUT2 "0\t";
    	    	    print OUT2n "0\t";
    	        }
    	     }}
    		print OUT2 $Time_half_p1{$half."__".$team}."\t";
    		print OUT2n $Time_half_p1{$half."__".$team}."\t";
    	    }
	print OUT2 "\n";
	print OUT2n "\n";
    }

    close(OUT2);
    close(OUT2n);
}
