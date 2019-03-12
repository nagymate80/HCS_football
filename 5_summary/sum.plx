#!/usr/bin/perl -w
$|++;
#
# give a summary for the half. Give details for player-pairs players and teams
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
my $OUTdatadir = "OUT";
my $line="";
my @datFiles = ();

my $ball="Ball";

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
    my $matchPart;
    my $matchHalf;
    my $player1="";
    my $player2="";
    my $inputFile=$INdatadir."/".$datFile;
    open(IN, "<$inputFile") || die ("Error: cannot read from $inputFile\n");
    
    my %HCS_match_part_p1_p2_best_posses=();
    my %Time_match_part_p1_p2=();
    my %match_players=();
    my %matches=();

    my $dataNum=0;
    while($line=<IN>){
	# skip comment lines and empty lines
	if(($line!~/^\s*\#/)&&($line!~/^\s*$/)){
	    chomp $line;
	    my @p = split (' ', $line);
	    my @p2 = split ('_', $p[0]);
	    my $matchName = $p2[0];
	    my $matchPart = $p2[1];
	    my $player1 = $p[1];
	    my $player2 = $p[2];
    	    $HCS_match_part_p1_p2_best_posses{$matchName."__".$matchPart."__".$player1."__".$player2."__0__1"} = $p[3];		#5
    	    $HCS_match_part_p1_p2_best_posses{$matchName."__".$matchPart."__".$player1."__".$player2."__1__1"} = $p[4];		#6
    	    $HCS_match_part_p1_p2_best_posses{$matchName."__".$matchPart."__".$player1."__".$player2."__0__2"} = $p[7];		#7
    	    $HCS_match_part_p1_p2_best_posses{$matchName."__".$matchPart."__".$player1."__".$player2."__1__2"} = $p[8];		#8
    	    $Time_match_part_p1_p2{$matchName."__".$matchPart."__".$player1."__".$player2} = $p[10];
    	    $dataNum++;
	    
	    if(not defined $matches{$matchName}){
		$matches{$matchName}=1;
	    }
	    if(not defined $match_players{$matchName."_".$player1}){
		$match_players{$matchName."__".$player1}=1;
	    }
	    if(not defined $match_players{$matchName."_".$player2}){
		$match_players{$matchName."__".$player2}=1;
	    }

	}
    }

    foreach my $match (sort keys %matches){
	my $outputFile="Postau/Postau_".$match;
	open(OUT, ">$outputFile") || die ("Error: cannot write to $outputFile, make directory: OUT\n");
	print OUT "#match\tID1\tID2\tpostau\tpostaubest\tpostauPosses1\tpostaubestPosses1\tpostauPosses2\tpostaubestPosses2\ttimetogether\t1Hpostau\t1Hpostaubest\t1HpostauPosses1\t1HpostaubestPosses1\t1HpostauPosses2\t1HpostaubestPosses2\t1Htimetogether\t2Hpostau\t2Hpostaubest\t2HpostauPosses1\t2HpostaubestPosses1\t2HpostauPosses2\t2HpostaubestPosses2\t2Htimetogether\n";
	my %players = ();
	foreach my $mplayer (sort keys %match_players){
	    my @p = split ('__', $mplayer);
	    if($match eq $p[0]){
		if(not defined $players{$p[1]}){
		    $players{$p[1]}=1;
		}
	    }
	}
	my %HCS_p1_p2_half_best_posses=();
	my %timetogether_p1_p2_half=();
	
	my @players = sort keys %players;
	foreach my $p1 (@players){
	 foreach my $p2 (@players){
	  if($p1 ne $p2){
		my %HCS_half_best_posses=();
		my %timetogether=();
		for(my $part = 1; $part<=6; $part++){
		    my $half=1;
		    if($part>3){
			$half=2;
		    }
			
			if(defined $HCS_match_part_p1_p2_best_posses{$match."__".$part."__".$p1."__".$p2."__0__1"}){
			    for(my $best=0; $best<=1; $best++){
			     for(my $posses=1; $posses<=2; $posses++){
				    #half 1 or 2
				    if(not defined $HCS_half_best_posses{$half."_".$best."_".$posses}){
					$HCS_half_best_posses{$half."_".$best."_".$posses} =  $HCS_match_part_p1_p2_best_posses{$match."__".$part."__".$p1."__".$p2."__".$best."__".$posses};
				    } else {
					$HCS_half_best_posses{$half."_".$best."_".$posses} += $HCS_match_part_p1_p2_best_posses{$match."__".$part."__".$p1."__".$p2."__".$best."__".$posses};
				    }
				     
				    if(not defined $HCS_half_best_posses{$half."_".$best."_0"}){
					$HCS_half_best_posses{$half."_".$best."_0"} =  $HCS_match_part_p1_p2_best_posses{$match."__".$part."__".$p1."__".$p2."__".$best."__".$posses};
				    } else {
					$HCS_half_best_posses{$half."_".$best."_0"} += $HCS_match_part_p1_p2_best_posses{$match."__".$part."__".$p1."__".$p2."__".$best."__".$posses};
				    }
				    #full match
				    if(not defined $HCS_half_best_posses{"0_".$best."_".$posses}){
					$HCS_half_best_posses{"0_".$best."_".$posses} =  $HCS_match_part_p1_p2_best_posses{$match."__".$part."__".$p1."__".$p2."__".$best."__".$posses};
				    } else {
					$HCS_half_best_posses{"0_".$best."_".$posses} += $HCS_match_part_p1_p2_best_posses{$match."__".$part."__".$p1."__".$p2."__".$best."__".$posses};
				    }
				    if(not defined $HCS_half_best_posses{"0_".$best."_0"}){
					$HCS_half_best_posses{"0_".$best."_0"} =  $HCS_match_part_p1_p2_best_posses{$match."__".$part."__".$p1."__".$p2."__".$best."__".$posses};
				    } else {
					$HCS_half_best_posses{"0_".$best."_0"} += $HCS_match_part_p1_p2_best_posses{$match."__".$part."__".$p1."__".$p2."__".$best."__".$posses};
				    }
			    }}
				    #time
				    if(not defined $timetogether{$half}){
					$timetogether{$half} = $Time_match_part_p1_p2{$match."__".$part."__".$p1."__".$p2};
				    } else {
					$timetogether{$half} += $Time_match_part_p1_p2{$match."__".$part."__".$p1."__".$p2};
				    }
				    if(not defined $timetogether{"0"}){
					$timetogether{"0"} =  $Time_match_part_p1_p2{$match."__".$part."__".$p1."__".$p2};
				    } else {
					$timetogether{"0"} += $Time_match_part_p1_p2{$match."__".$part."__".$p1."__".$p2};
				    }
			}
		}	
		print OUT "$match\t$p1\t$p2\t";
		    for(my $half=0; $half<=2; $half++){
		     for(my $posses=0; $posses<=2; $posses++){
		      for(my $best=0; $best<=1; $best++){
		    	    if(defined $HCS_half_best_posses{$half."_".$best."_".$posses}){
		    		print OUT $HCS_half_best_posses{$half."_".$best."_".$posses}."\t";
		    		$HCS_p1_p2_half_best_posses{$p1."_".$p2."_".$half."_".$best."_".$posses} = $HCS_half_best_posses{$half."_".$best."_".$posses};
		    	    } else {
		    		print OUT "0\t";
		    	    }
		      }
		     }
			if(defined $timetogether{$half}){
			    print OUT $timetogether{$half}."\t";
			    $timetogether_p1_p2_half{$p1."_".$p2."_".$half}=$timetogether{$half};
			} else {
			    print OUT "0\t";
			}
		    }
		print OUT "\n";
	}}}
	
	close (OUT);
	$outputFile="HCS/HCS_".$match;
	open(OUT, ">$outputFile") || die ("Error: cannot write to $outputFile, make directory: OUT\n");
	print OUT "#match\tID1\tID2\tHCS\tHCSbest\tHCSPosses1\tHCSbestPosses1\tHCSPosses2\tHCSbestPosses2\ttimetogether\t1HHCS\t1HHCSbest\t1HHCSPosses1\t1HHCSbestPosses1\t1HHCSPosses2\t1HHCSbestPosses2\t1Htimetogether\t2HHCS\t2HHCSbest\t2HHCSPosses1\t2HHCSbestPosses1\t2HHCSPosses2\t2HHCSbestPosses2\t2Htimetogether\n";
	my $outputFile2="PosNeg/PosNeg_".$match;
	open(OUT2, ">$outputFile2") || die ("Error: cannot write to $outputFile2, make directory: OUT\n");
	print OUT2 "#match\tID1\tID2\tPosNeg\tPosNegbest\tPosNegPosses1\tPosNegbestPosses1\tPosNegPosses2\tPosNegbestPosses2\ttimetogether\t1HPosNeg\t1HPosNegbest\t1HPosNegPosses1\t1HPosNegbestPosses1\t1HPosNegPosses2\t1HPosNegbestPosses2\t1Htimetogether\t2HPosNeg\t2HPosNegbest\t2HPosNegPosses1\t2HPosNegbestPosses1\t2HPosNegPosses2\t2HPosNegbestPosses2\t2Htimetogether\n";
	my $outputFileP1="Player/PlayerPosNeg_Same_".$match;
	open(OUTp1, ">$outputFileP1") || die ("Error: cannot write to $outputFileP1, make directory: OUT\n");
	print OUTp1 "#match\tID1\tPosNeg\tPosNegbest\tPosNegPosses1\tPosNegbestPosses1\tPosNegPosses2\tPosNegbestPosses2\ttimetogether\t1HPosNeg\t1HPosNegbest\t1HPosNegPosses1\t1HPosNegbestPosses1\t1HPosNegPosses2\t1HPosNegbestPosses2\t1Htimetogether\t2HPosNeg\t2HPosNegbest\t2HPosNegPosses1\t2HPosNegbestPosses1\t2HPosNegPosses2\t2HPosNegbestPosses2\t2Htimetogether\n";
	my $outputFileP2="Player/PlayerPosNeg_Opp_".$match;
	open(OUTp2, ">$outputFileP2") || die ("Error: cannot write to $outputFileP2, make directory: OUT\n");
	print OUTp2 "#match\tID1\tPosNeg\tPosNegbest\tPosNegPosses1\tPosNegbestPosses1\tPosNegPosses2\tPosNegbestPosses2\ttimetogether\t1HPosNeg\t1HPosNegbest\t1HPosNegPosses1\t1HPosNegbestPosses1\t1HPosNegPosses2\t1HPosNegbestPosses2\t1Htimetogether\t2HPosNeg\t2HPosNegbest\t2HPosNegPosses1\t2HPosNegbestPosses1\t2HPosNegPosses2\t2HPosNegbestPosses2\t2Htimetogether\n";
	my $outputFileP3="Player/PlayerPosNeg_Ball_".$match;
	open(OUTp3, ">$outputFileP3") || die ("Error: cannot write to $outputFileP3, make directory: OUT\n");
	print OUTp3 "#match\tID1\tPosNeg\tPosNegbest\tPosNegPosses1\tPosNegbestPosses1\tPosNegPosses2\tPosNegbestPosses2\ttimetogether\t1HPosNeg\t1HPosNegbest\t1HPosNegPosses1\t1HPosNegbestPosses1\t1HPosNegPosses2\t1HPosNegbestPosses2\t1Htimetogether\t2HPosNeg\t2HPosNegbest\t2HPosNegPosses1\t2HPosNegbestPosses1\t2HPosNegPosses2\t2HPosNegbestPosses2\t2Htimetogether\n";
	my $outputFileP0="Player/PlayerPosNeg_All_".$match;
	open(OUTp0, ">$outputFileP0") || die ("Error: cannot write to $outputFileP0, make directory: OUT\n");
	print OUTp0 "#match\tID1\tPosNeg\tPosNegbest\tPosNegPosses1\tPosNegbestPosses1\tPosNegPosses2\tPosNegbestPosses2\ttimetogether\t1HPosNeg\t1HPosNegbest\t1HPosNegPosses1\t1HPosNegbestPosses1\t1HPosNegPosses2\t1HPosNegbestPosses2\t1Htimetogether\t2HPosNeg\t2HPosNegbest\t2HPosNegPosses1\t2HPosNegbestPosses1\t2HPosNegPosses2\t2HPosNegbestPosses2\t2Htimetogether\n";
	my $outputFileI1="Player/PlayerHCS_Same_".$match;
	open(OUTi1, ">$outputFileI1") || die ("Error: cannot write to $outputFileP1, make directory: OUT\n");
	print OUTi1 "#match\tID1\tHCS\tHCSbest\tHCSPosses1\tHCSbestPosses1\tHCSPosses2\tHCSbestPosses2\ttimetogether\t1HHCS\t1HHCSbest\t1HHCSPosses1\t1HHCSbestPosses1\t1HHCSPosses2\t1HHCSbestPosses2\t1Htimetogether\t2HHCS\t2HHCSbest\t2HHCSPosses1\t2HHCSbestPosses1\t2HHCSPosses2\t2HHCSbestPosses2\t2Htimetogether\n";
	my $outputFileI2="Player/PlayerHCS_Opp_".$match;
	open(OUTi2, ">$outputFileI2") || die ("Error: cannot write to $outputFileP2, make directory: OUT\n");
	print OUTi2 "#match\tID1\tHCS\tHCSbest\tHCSPosses1\tHCSbestPosses1\tHCSPosses2\tHCSbestPosses2\ttimetogether\t1HHCS\t1HHCSbest\t1HHCSPosses1\t1HHCSbestPosses1\t1HHCSPosses2\t1HHCSbestPosses2\t1Htimetogether\t2HHCS\t2HHCSbest\t2HHCSPosses1\t2HHCSbestPosses1\t2HHCSPosses2\t2HHCSbestPosses2\t2Htimetogether\n";
	my $outputFileI3="Player/PlayerHCS_Ball_".$match;
	open(OUTi3, ">$outputFileI3") || die ("Error: cannot write to $outputFileP3, make directory: OUT\n");
	print OUTi3 "#match\tID1\tHCS\tHCSbest\tHCSPosses1\tHCSbestPosses1\tHCSPosses2\tHCSbestPosses2\ttimetogether\t1HHCS\t1HHCSbest\t1HHCSPosses1\t1HHCSbestPosses1\t1HHCSPosses2\t1HHCSbestPosses2\t1Htimetogether\t2HHCS\t2HHCSbest\t2HHCSPosses1\t2HHCSbestPosses1\t2HHCSPosses2\t2HHCSbestPosses2\t2Htimetogether\n";
	my $outputFileI0="Player/PlayerHCS_All_".$match;
	open(OUTi0, ">$outputFileI0") || die ("Error: cannot write to $outputFileP0, make directory: OUT\n");
	print OUTi0 "#match\tID1\tHCS\tHCSbest\tHCSPosses1\tHCSbestPosses1\tHCSPosses2\tHCSbestPosses2\ttimetogether\t1HHCS\t1HHCSbest\t1HHCSPosses1\t1HHCSbestPosses1\t1HHCSPosses2\t1HHCSbestPosses2\t1Htimetogether\t2HHCS\t2HHCSbest\t2HHCSPosses1\t2HHCSbestPosses1\t2HHCSPosses2\t2HHCSbestPosses2\t2Htimetogether\n";


	foreach my $p1 (@players){
	 my $t1 = $ball;
	 if($p1 ne $ball){
		my @p = split ('_', $p1);
		$t1 = $p[0];
	 }
	 my %player_HCS_sameteam=();
	 my %player_posneg_sameteam=();
	 my %player_time_sameteam=();
	 
	 for(my $st=1; $st<=3; $st++){
	  for(my $half=0; $half<=2; $half++){
	   for(my $posses=0; $posses<=2; $posses++){
	    for(my $best=0; $best<=1; $best++){
		$player_HCS_sameteam{$st."_".$half."_".$best."_".$posses}=0;
		$player_posneg_sameteam{$st."_".$half."_".$best."_".$posses}=0;
	   }}
		$player_time_sameteam{$st."_".$half}=0;
	 }}

	 foreach my $p2 (@players){
	  if($p1 ne $p2){
		my $t2 = $ball;
		my $sameteam = 3;	# sameteam: 0 = all data,	1 = same team,	2 = opposite team,	3 = ball
		if($p2 ne $ball){
		    my @p = split ('_', $p2);
		    $t2 = $p[0];
		    if($t1 eq $t2){
			$sameteam = 1;
		    } else {
			$sameteam = 2;
		    }
		    #print "SameOpp: $p1\t$p2\t$sameteam\n";
		}
		
		print OUT "$match\t$p1\t$p2\t";
		print OUT2 "$match\t$p1\t$p2\t";
		    for(my $half=0; $half<=2; $half++){
		     for(my $posses=0; $posses<=2; $posses++){
		      for(my $best=0; $best<=1; $best++){
		    	    my $HCS=0;
		    	    my $posneg=0;
		    	    if(defined $HCS_p1_p2_half_best_posses{$p1."_".$p2."_".$half."_".$best."_".$posses}){
		    		$HCS += $HCS_p1_p2_half_best_posses{$p1."_".$p2."_".$half."_".$best."_".$posses};
		    		$posneg += $HCS_p1_p2_half_best_posses{$p1."_".$p2."_".$half."_".$best."_".$posses};
		    		#player sum
		    		$player_HCS_sameteam{$sameteam."_".$half."_".$best."_".$posses} += $HCS_p1_p2_half_best_posses{$p1."_".$p2."_".$half."_".$best."_".$posses};
		    		$player_posneg_sameteam{$sameteam."_".$half."_".$best."_".$posses} += $HCS_p1_p2_half_best_posses{$p1."_".$p2."_".$half."_".$best."_".$posses};
		    		if($sameteam!=3){
		    		    $player_HCS_sameteam{"0_".$half."_".$best."_".$posses} += $HCS_p1_p2_half_best_posses{$p1."_".$p2."_".$half."_".$best."_".$posses};
		    		    $player_posneg_sameteam{"0_".$half."_".$best."_".$posses} += $HCS_p1_p2_half_best_posses{$p1."_".$p2."_".$half."_".$best."_".$posses};
		    		}
		    		#team sum
		    		##$team_HCS_sameteam{$t1."_".$sameteam} += $HCS_p1_p2_half_best_posses{$p1."_".$p2."_".$half."_".$best."_".$posses};
		    		##$team_posneg_sameteam{$t1."_".$sameteam} += $HCS_p1_p2_half_best_posses{$p1."_".$p2."_".$half."_".$best."_".$posses};
		    	    }
		    	    if(defined $HCS_p1_p2_half_best_posses{$p2."_".$p1."_".$half."_".$best."_".$posses}){
		    		$HCS += $HCS_p1_p2_half_best_posses{$p2."_".$p1."_".$half."_".$best."_".$posses};
		    		$posneg -= $HCS_p1_p2_half_best_posses{$p2."_".$p1."_".$half."_".$best."_".$posses};
		    		#player sum
		    		$player_HCS_sameteam{$sameteam."_".$half."_".$best."_".$posses} += $HCS_p1_p2_half_best_posses{$p2."_".$p1."_".$half."_".$best."_".$posses};
		    		$player_posneg_sameteam{$sameteam."_".$half."_".$best."_".$posses} -= $HCS_p1_p2_half_best_posses{$p2."_".$p1."_".$half."_".$best."_".$posses};
		    		if($sameteam != 3){
		    		    $player_HCS_sameteam{"0_".$half."_".$best."_".$posses} += $HCS_p1_p2_half_best_posses{$p2."_".$p1."_".$half."_".$best."_".$posses};
		    		    $player_posneg_sameteam{"0_".$half."_".$best."_".$posses} -= $HCS_p1_p2_half_best_posses{$p2."_".$p1."_".$half."_".$best."_".$posses};
		    		}
		    		#team sum
		    		##$team_HCS_sameteam{$t1."_".$sameteam} += $HCS_p1_p2_half_best_posses{$p2."_".$p1."_".$half."_".$best."_".$posses};
		    		##$team_posneg_sameteam{$t1."_".$sameteam} -= $HCS_p1_p2_half_best_posses{$p1."_".$p2."_".$half."_".$best."_".$posses};
		    	    }
		    	    print OUT $HCS."\t";
		    	    print OUT2 $posneg."\t";
		     }}
		    	    if(defined $timetogether_p1_p2_half{$p1."_".$p2."_".$half}){
				print OUT $timetogether_p1_p2_half{$p1."_".$p2."_".$half}."\t";
				print OUT2 $timetogether_p1_p2_half{$p1."_".$p2."_".$half}."\t";
				#player sum
				$player_time_sameteam{$sameteam."_".$half} += $timetogether_p1_p2_half{$p1."_".$p2."_".$half};
				$player_time_sameteam{"0_".$half} += $timetogether_p1_p2_half{$p1."_".$p2."_".$half};
				##$team_time_sameteam{$t1."_".$sameteam} += $timetogether_p1_p2_half{$p1."_".$p2."_".$half};
			    } else {
				print OUT "0\t";
				print OUT2 "0\t";
			    }
		    }
		print OUT "\n";
		print OUT2 "\n";
	 }}
	 # Print out player data
		print OUTp0 "$match\t$p1\t";
		print OUTp1 "$match\t$p1\t";
		print OUTp2 "$match\t$p1\t";
		print OUTp3 "$match\t$p1\t";
		print OUTi0 "$match\t$p1\t";
		print OUTi1 "$match\t$p1\t";
		print OUTi2 "$match\t$p1\t";
		print OUTi3 "$match\t$p1\t";
		    for(my $half=0; $half<=2; $half++){
		     for(my $posses=0; $posses<=2; $posses++){
		      for(my $best=0; $best<=1; $best++){
			    my $sameteam = 1;
			    if(defined $player_HCS_sameteam{$sameteam."_".$half."_".$best."_".$posses}){
				print OUTi1 $player_HCS_sameteam{$sameteam."_".$half."_".$best."_".$posses}."\t";
			    } else{
				print OUTi1 "0\t";
			    }
			    if(defined $player_posneg_sameteam{$sameteam."_".$half."_".$best."_".$posses}){
				print OUTp1 $player_posneg_sameteam{$sameteam."_".$half."_".$best."_".$posses}."\t";
			    } else{
				print OUTp1 "0\t";
			    }
			    $sameteam = 2;
			    if(defined $player_HCS_sameteam{$sameteam."_".$half."_".$best."_".$posses}){
				print OUTi2 $player_HCS_sameteam{$sameteam."_".$half."_".$best."_".$posses}."\t";
			    } else{
				print OUTi2 "0\t";
			    }
			    if(defined $player_posneg_sameteam{$sameteam."_".$half."_".$best."_".$posses}){
				print OUTp2 $player_posneg_sameteam{$sameteam."_".$half."_".$best."_".$posses}."\t";
			    } else{
				print OUTp2 "0\t";
			    }
			    $sameteam = 3;
			    if(defined $player_HCS_sameteam{$sameteam."_".$half."_".$best."_".$posses}){
				print OUTi3 $player_HCS_sameteam{$sameteam."_".$half."_".$best."_".$posses}."\t";
			    } else{
				print OUTi3 "0\t";
			    }
			    if(defined $player_posneg_sameteam{$sameteam."_".$half."_".$best."_".$posses}){
				print OUTp3 $player_posneg_sameteam{$sameteam."_".$half."_".$best."_".$posses}."\t";
			    } else{
				print OUTp3 "0\t";
			    }
			    $sameteam = 0;
			    if(defined $player_HCS_sameteam{$sameteam."_".$half."_".$best."_".$posses}){
				print OUTi0 $player_HCS_sameteam{$sameteam."_".$half."_".$best."_".$posses}."\t";
			    } else{
				print OUTi0 "0\t";
			    }
			    if(defined $player_posneg_sameteam{$sameteam."_".$half."_".$best."_".$posses}){
				print OUTp0 $player_posneg_sameteam{$sameteam."_".$half."_".$best."_".$posses}."\t";
			    } else{
				print OUTp0 "0\t";
			    }    
		     }}
		     	    if(defined $player_time_sameteam{"0_".$half}){
				print OUTp0 $player_time_sameteam{"0_".$half}."\t";
				print OUTi0 $player_time_sameteam{"0_".$half}."\t";
			    } else {
				print OUTp0 "0\t";
				print OUTi0 "0\t";
			    }
		     	    if(defined $player_time_sameteam{"1_".$half}){
				print OUTp1 $player_time_sameteam{"1_".$half}."\t";
				print OUTi1 $player_time_sameteam{"1_".$half}."\t";
			    } else {
				print OUTp1 "0\t";
				print OUTi1 "0\t";
			    }
		     	    if(defined $player_time_sameteam{"2_".$half}){
				print OUTp2 $player_time_sameteam{"2_".$half}."\t";
				print OUTi2 $player_time_sameteam{"2_".$half}."\t";
			    } else {
				print OUTp2 "0\t";
				print OUTi2 "0\t";
			    }
		     	    if(defined $player_time_sameteam{"3_".$half}){
				print OUTp3 $player_time_sameteam{"3_".$half}."\t";
				print OUTi3 $player_time_sameteam{"3_".$half}."\t";
			    } else {
				print OUTp3 "0\t";
				print OUTi3 "0\t";
			    }
		    }
			
		print OUTp0 "\n";
		print OUTp1 "\n";
		print OUTp2 "\n";
		print OUTp3 "\n";
		print OUTi0 "\n";
		print OUTi1 "\n";
		print OUTi2 "\n";
		print OUTi3 "\n";
	}
    }
    close(OUT);
    close(OUT2);
}
