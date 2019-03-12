#!/usr/bin/perl -w
#
# make summary output file
# Get highest correlation, when other is below the treshold
# Read positions, dMAX on interactions
# Note: the script was tested and run on
# linux (Ubuntu, 18.04.2 LTS (Bionic Beaver), 4.15.0-43-generic) using
# perl 5, version 26, subversion 1 (v5.26.1) built for x86_64-linux-gnu-thread-multi
#

use strict;
use warnings;
#use File::chdir;
use Cwd;

sub round {
    my($number) = shift;
        return int($number + .5);
}


my $CorMIN=0.97;
my $dMAX=10;	

my $tauMAX=4;

my $timeSTART0 = 1000000;
my $timeBIN = 6000;
my $deltaT = 10;

my $TRES = 25;		# number of frames binned
my $limitForBall = 20;	# number of good data point per bins (max is TRES)

my $ball= "Ball";

##############################################################################
##########                 Read from input files		##############
##############################################################################

my $INdatadir = shift @ARGV;
#my $BALLfile = shift @ARGV;
my $POSdatadir = shift @ARGV;
my $OUTdatadir="OUT/".$INdatadir;

    if(-d $OUTdatadir){
	`rm -r $OUTdatadir/*`;
    } else {
	`mkdir $OUTdatadir`;
    }


my $line="";
my @datFiles = ();

my @posFiles=();
# Read Postion of All players
opendir (posDIR, $POSdatadir) or die "Unable to open directory: $!";
while (my $file_name = readdir(posDIR)) {
    if (length($file_name) >2) {
	push @posFiles, $file_name;
    }
}

my ($frame, $X, $Y);
my %X=();
my %Y=();
my %frames=();
my %teams=();
my %teamnames=();

my $inputFile;
#undef $t_last;
foreach my $posFile (@posFiles){
    #chdir($currentDir);
    my @p = split("pID_", $posFile);
    my $i = $p[1];
    
    if($i ne $ball){
	my @p2 = split("_", $i);
        #my @p3 = split("-", $p2[0]);
        my $team = $p2[0];
	$teams{$i} = $team;
	if(!defined $teamnames{$team}){
	    $teamnames{$team}=1;
	}

	#print "team: $team\tpID: $i\n"; #TEST
    }
    
    $inputFile=$POSdatadir."/".$posFile;
    open(IN, "<$inputFile") || die ("Error: cannot read from $inputFile\n");

    while($line=<IN>){
	# skip comment lines and empty lines
	if(($line!~/^\s*\#/)&&($line!~/^\s*$/)){
	    chomp $line;
	    ($frame, $X, $Y, my @rest) = split(' ',$line);
	    my $t = $timeSTART0 + $frame*$deltaT;
	    $X{$t."_".$i} = $X;
	    $Y{$t."_".$i} = $Y;
	    if(!defined $frames{$frame}){ $frames{$frame}=1; }

	 }     
    }
    close(IN);
}


# Read interaction file names
opendir (directory_handle, $INdatadir) or die "Unable to open directory: $!";
while (my $file_name = readdir(directory_handle)) {
    if (length($file_name) >2) {
	push @datFiles, $file_name;
    }
}




##############################################################################
##########                 Files				##############
##############################################################################

my ($outputFile1, $outputFile2, $outputFile3, $outputFile4, $outputFile5, $outputFile6);
my $oldtime=0;

my ($time, $i, $j, $tau, $Cor, $dist);

##############################################################################
##########                 Read Data from files			##############
##############################################################################


my $tauStep=0.2;
my $CorStep=0.001;
my $distStep=2;

my $currentDir=getcwd();

    my %times=();
    my %Cor_t_i_j=();
    my %tau_t_i_j=();
    my %tau_i_j=();
    my %tauBEST_i_j=();

    my %IDs=();
    my %taus=();
    my %Cors=();
    my %dists=();

    my %InterTeam_team_time=();
    my %IntraTeam_team_time=();
    my %InterTeam_team_Posses_time=();
    my %IntraTeam_team_Posses_time=();
    my %timeBINs=();
foreach my $datFile (@datFiles){
    #chdir($currentDir);
    my @p = split("pID_", $datFile);
    my $iPre = substr($p[1], 0, -1);
    my @p2 = split("_DFL_DFL", $iPre);
    my $i = $p2[0];
    my $j = $p[2];
    #print "$datFile\t$i\t$j\n";		#TEST
    
    $inputFile=$INdatadir."/".$datFile;
    open(IN, "<$inputFile") || die ("Error: cannot read from $inputFile\n");

    while($line=<IN>){
	# skip comment lines and empty lines
	if(($line!~/^\s*\#/)&&($line!~/^\s*$/)){
	    chomp $line;
	    ($time, $Cor, $tau, my @rest) = split(' ',$line);
	    $tau = -(-$tau);
	    
	    if(($Cor>$CorMIN) && ($time>0)){
	      if((defined $X{$time."_".$i}) && (defined $X{$time."_".$j})){
	       my $dSQR = ($X{$time."_".$i} - $X{$time."_".$j})**2 + ($Y{$time."_".$i} - $Y{$time."_".$j})**2;
	       if($dSQR < $dMAX**2){
		if($tau>0){
		    $tau_t_i_j{$time."_".$i."_".$j} = $tau;
		    $Cor_t_i_j{$time."_".$i."_".$j} = $Cor;
		} elsif ($tau<0){
		    ### REVERSE if tau is negative!
		    $tau_t_i_j{$time."_".$j."_".$i} = -$tau;
		    $Cor_t_i_j{$time."_".$j."_".$i} = $Cor;
		}
		if(!defined $times{$time}){ $times{$time}=1; }
	       }
	      } else {
	        print "ERROR: player's position not defined!\ttime: $time\ti: $i\tj: $j\n";
	      }
	      if(!defined $IDs{$i}){ $IDs{$i}=1; }
	      if(!defined $IDs{$j}){ $IDs{$j}=1; }
	      if(!defined $taus{$tau}){ $taus{$tau}=1; }
	    }
	    
	 }     
    }
    close(IN);
}

 ##############################################################################
 ##########		Calculate and write out data		##############
 ##############################################################################

 my @order = sort keys %IDs;
 my @taus = sort { $a <=> $b } keys (%taus);
 my @times = sort { $a <=> $b } keys (%times);
 my @teamnames = sort keys %teamnames;


 # Calculate time each pair is playing together
 my %framestogether = ();
 my @frames = sort { $a <=> $b } keys (%frames);

 foreach my $f (@frames){
    my $t = $timeSTART0 + $f*$deltaT;
    if(($t>=$times[0]) && ($t<=$times[-1]+$TRES*$deltaT)){
      foreach $i (@order){
	foreach $j (@order){
	    if($i ne $j){
		    if((defined $X{$t."_".$i}) && (defined $X{$t."_".$j}) ){
			if(    ($X{$t."_".$i} ne "nan") && ($X{$t."_".$j} ne "nan")
			    && (($X{$t."_".$i}!=0)||($Y{$t."_".$i}!=0)) && (($X{$t."_".$j}!=0)||($Y{$t."_".$j}!=0)) ){
				$framestogether{$i."_".$j}++;
			}
		    }
	    }
	}
      }
    }
 }


 my %tauBEST_t_i_j=();
 
 foreach my $t (@times){
     foreach $j (@order){
	my $iBEST="";
	my $corBEST="";
	foreach $i (@order){
	 if($i ne $j){
	    #print "t: $t\ti: $i\tj: $j\t";	#TEST
    	    if(defined $Cor_t_i_j{$t."_".$i."_".$j}){
    		$tau = $tau_t_i_j{$t."_".$i."_".$j};
    		#print "$i\t$j\t$tau\t".$Cor_t_i_j{$t."_".$i."_".$j}."\n";	#TEST
    		$tau_i_j{$tau."_".$i."_".$j}++;
		#printf $tau."$i\t$j\t".$tau_i_j{$tau."_".$i."_".$j}."\n"; #TEST
    		if($iBEST ne ""){
    		    if($Cor_t_i_j{$t."_".$i."_".$j}>$corBEST){
    			$iBEST=$i;
    			$corBEST = $Cor_t_i_j{$t."_".$i."_".$j};
    		    }
    		} else {
    		    $iBEST = $i;
    		    $corBEST = $Cor_t_i_j{$t."_".$i."_".$j};
    		}
    	    }
         }
        }
	if($iBEST ne ""){
	    my $tauBEST = $tau_t_i_j{$t."_".$iBEST."_".$j};
	    $tauBEST_i_j{$tauBEST."_".$iBEST."_".$j}++;
	    $tauBEST_t_i_j{$t."_".$iBEST."_".$j} = $tauBEST;
	}

    }
 }
 
 # SUMMARY        
 print "#INdatadir\tID1\tID2\tpostau\tpostauBest\tpostauPosses1\tpostauBestPosses2\tpostauPosses2\tpostauBestPosses2\tframesTogether\ttimeTogether(s)\n";

 foreach $i (@order){
     foreach $j (@order){
      if($i ne $j){
	 my @postau = ();
         my @postauBEST = ();
	 for(my $num=0; $num<3; $num++){
	    $postau[$num]=0;
	    $postauBEST[$num]=0;
	 }
	 my $outputFileTau=$OUTdatadir."/tau_pID_".$i."_pID_".$j;
	 open(OUTtau, ">$outputFileTau") || die ("Error: cannot write to $outputFileTau\n");
	 printf OUTtau "#Tau(cs)\thist\thist(HighestCorFollow)\n";
	
	foreach my $t (@times){
	    if((defined $tau_t_i_j{$t."_".$i."_".$j}) && ($tau_t_i_j{$t."_".$i."_".$j}>0)){
		$postau[0] ++;
		if((defined $tauBEST_t_i_j{$t."_".$i."_".$j}) && ($tauBEST_t_i_j{$t."_".$i."_".$j}>0)){
		    $postauBEST[0] ++;
		}
	    }
	}
	
	foreach $tau (@taus){
          if(defined $tau_i_j{$tau."_".$i."_".$j}){
	    printf OUTtau $tau."\t".$tau_i_j{$tau."_".$i."_".$j};
          } else {
	    printf OUTtau "$tau\t0";
          }
          if(defined $tauBEST_i_j{$tau."_".$i."_".$j}){
	    printf OUTtau "\t".$tauBEST_i_j{$tau."_".$i."_".$j}."\n";
          } else {
	    printf OUTtau "\t0\n";
          }


	}
	 close(OUTtau);
	 if(!defined $framestogether{$i."_".$j}){
	    $framestogether{$i."_".$j}=0;
	 }
         printf "$INdatadir\t$i\t$j\t$postau[0]\t$postauBEST[0]\t$postau[1]\t$postauBEST[1]\t$postau[2]\t$postauBEST[2]\t".$framestogether{$i."_".$j}."\t%.2f\n",
            $framestogether{$i."_".$j}*$deltaT/100.0;

      }
     }
 }

 # Print out interaction on the highest cor, and separated based on ball possession
 my $outputFileInter=$OUTdatadir."/InterALL";
 open(OUTinter, ">$outputFileInter") || die ("Error: cannot write to $outputFileInter\n");

 $line = "#Frame\tTime(cs)\ti\tj\ttau\tCor\n";
 printf OUTinter $line;
 foreach my $t (@times){
   foreach $i (@order){
     foreach $j (@order){
        if($i ne $j){
	    if(defined $tauBEST_t_i_j{$t."_".$i."_".$j}){
		my $frame = int( ($t - $timeSTART0) / $deltaT);
		my $tau = $tauBEST_t_i_j{$t."_".$i."_".$j};
		my $Cor = $Cor_t_i_j{$t."_".$i."_".$j};
		$line = "$frame\t$t\t$i\t$j\t$tau\t$Cor\n";
		print OUTinter $line;
	    }
	    if((defined $Cor_t_i_j{$t."_".$i."_".$j}) && ( $Cor_t_i_j{$t."_".$i."_".$j} >$CorMIN ) ){
    		    # SAME Team
    		if((defined $teams{$i}) && (defined $teams{$j})){
    		    if($teams{$i} eq $teams{$j}){
    			if(defined $IntraTeam_team_time{$teams{$i}."_".( (round($t/$timeBIN))*$timeBIN)}){
    			    $IntraTeam_team_time{$teams{$i}."_".( (round($t/$timeBIN))*$timeBIN)}++;
    			} else {
    			    $IntraTeam_team_time{$teams{$i}."_".( (round($t/$timeBIN))*$timeBIN)}=1;
    			}
    		    } else {
    		    # Opposite Team
    			if(defined $InterTeam_team_time{$teams{$i}."_".( (round($t/$timeBIN))*$timeBIN)}){
    			    $InterTeam_team_time{$teams{$i}."_".( (round($t/$timeBIN))*$timeBIN)}++;
    			} else {
    			    $InterTeam_team_time{$teams{$i}."_".( (round($t/$timeBIN))*$timeBIN)}=1;
    			}
    		    }
    		    if(! defined $timeBINs{((round($t/$timeBIN))*$timeBIN)}) {
    			$timeBINs{((round($t/$timeBIN))*$timeBIN)} =1;
    		    }
		}
	    }
 }}}}
 close(OUTinter);
