#!/usr/bin/perl -w
$|++;
#
# calculation run in CUDA this only generates input file for that!
# Note: the script was tested and run on
# linux (Ubuntu, 18.04.2 LTS (Bionic Beaver), 4.15.0-43-generic) using
# perl 5, version 26, subversion 1 (v5.26.1) built for x86_64-linux-gnu-thread-multi
#
# author: Mate Nagy
# to use: *.plx (input_files_DIRECTORY)

####################################################################################################################
###														 ###
### to run in a folder with the follow sub-folders: DATA (with the original data files, with x and y in meters), ###
### OUT (where the files will be stored), and OUTWINDATA (where more the files will be stored).                  ###
###	files should named as "TeamA_player1.txt"								 ###
### put the script in the same folder and use in the shell:  "./calc_localcorr.plx DATA 1"                       ###
###		##Change the deltaT to 20 if data were in 5 Hz;	to 10 if data were in 10Hz			 ###
####################################################################################################################
use strict;
use warnings;

use Math::Derivative qw(Derivative1 Derivative2);
use Math::Trig ':pi';
 
my $deltaT=10; #### in centisecs! !!!!!!!!!!!
my $SmoothTheDataFunctions=0;

my $timeTogetherStart0 = 1000000;  
my $timeTogetherStartFIXED  ;	#1000000;  
my $timeTogetherEndFIXED   ;	#1120000; 

my $printForCuda=1;


my $TEST=0;
my $CalcCROSSCOR=0;	#for testing do not calculate crosscorrelation

my $distMAXtocalcCrosscor=100;		#100 #TEST_PUBLIC_DATA

my $DistLIMIT=$distMAXtocalcCrosscor;	#100 #TEST_PUBLIC_DATA
my $DistMINforDist=$distMAXtocalcCrosscor;	#changed20110109

##############################################################################
##########              	Functions			##############
##############################################################################

sub min {
    if ($_[0]>$_[1]) {return $_[1]} else {return $_[0]};
} 

sub max {
    if ($_[0]<$_[1]) {return $_[1]} else {return $_[0]};
} 

sub gauss {
    #### gauss function, gauss(x,sigma) 
    return  ((1/((sqrt(2*pi))*$_[1])) * exp(-($_[0]**2)/(2*$_[1]**2)));
} 

sub asin { atan2($_[0], sqrt(1 - $_[0] * $_[0])) }

sub vov {
    my ($ax, $ay, $az, $bx, $by, $bz)=@_;
    return $ax*$bx+$ay*$by+$az*$bz;
}
 
sub anglecosv_v {
    my ($ax, $ay, $az, $bx, $by, $bz)=@_;
    return (&vov($ax, $ay, $az, $bx, $by, $bz)/( &vectorAbs($ax, $ay, $az) * &vectorAbs($bx, $by, $bz) ));
}

				
	     
sub vectorAbs {
    my $abs=0;
    my @vector=@_;
    for(@vector){
	$abs += $_*$_;
    }
    #sqrt( $_[0]*$_[0] + $_[1]*$_[1] + $_[2]*$_[2] );
    return sqrt($abs);
}


sub vxv {
    my ($ax, $ay, $az, $bx, $by, $bz)=@_;
    my @v=();
    push @v, $ay*$bz-$az*$by; 
    push @v, $az*$bx-$ax*$bz; 
    push @v, $ax*$by-$ay*$bx; 
    return @v;
}



sub funcPower {
    my ($x,$a)=@_;
    my @y;
    my $n=$#{$x};
    for(my $i=0; $i<$n; $i++) {
	push @y, ($x->[$i])**$a;
    }
    return @y;
}

sub round {
    my($number) = shift;
        return int($number + .5);
}


##############################################################################
##########                 Read from input files		##############
##############################################################################

my $INdatadir = shift @ARGV;

my $RUNNUM = shift @ARGV;
my @p1 = split ('_', $RUNNUM);
$RUNNUM = $p1[0];
$timeTogetherStartFIXED = $p1[1];
$timeTogetherEndFIXED = $p1[2];

my $OUTdatadir="OUT/".$INdatadir."_".$RUNNUM;

my $OUTtrajdir="OUTtraj/".$INdatadir."_".$RUNNUM;

my @datFiles = @ARGV;		### so srcipt will only run on several files that is given as arguments to the program

my $line;

unless(-e $OUTdatadir or mkdir $OUTdatadir) {
	die "Unable to create $OUTdatadir";
}

unless(-e $OUTtrajdir or mkdir $OUTtrajdir) {
	die "Unable to create $OUTtrajdir";
}



##############################################################################
##########                 Global Variables			##############
##############################################################################

###### variables that we use in this version

my ($timeTogetherStart, $timeTogetherEnd);
my (@timeStart, @timeEnd);

my $time=0;
my %X_t=(); my %Y_t=(); my %Z_t=();
my %dXdT_t=(); my %dYdT_t=(); my %dZdT_t=();
my %d2XdT2_t=(); my %d2YdT2_t=(); my %d2ZdT2_t=();
my %gooddata_t=(); my %useforstat_t=();

my %pID=();


my @d=();          

my $dataNum=0;
my $inputFile;
my $oldtime=0;


if($TEST){ my $inputFileTEST="test.txt"; open(TEST, ">>$inputFileTEST") || die ("Error: cannot write to $inputFile\n"); }

    
my $fileNum=0;
foreach my $datFile (@datFiles){
    $fileNum++;
    # TeamA_player1.txt
    print "$datFile\n";
    ##### Get gpsID from filename
    my @p1 = split ('pID_', $datFile);
    #my $team = substr($p1[0],0,1);
    my $player = $p1[1];
    $pID{$fileNum} = $player;
    
    if($TEST){ print TEST "$fileNum pID: $pID{$fileNum}\n"; } #test
    
    ##########################################################################
    ######		Read data from input files			######
    ##########################################################################
    my @X=(); my @Y=(); my @time=();
    
    $inputFile=$INdatadir."/".$datFile;
    open(IN, "<$inputFile") || die ("Error: cannot read from $inputFile\n");
    
    $dataNum=0;	
    while($line=<IN>){
	# skip comment lines and empty lines
	if(($line!~/^\s*\#/)&&($line!~/^\s*$/)){
	    chomp $line;
	    my @pars = split (' ', $line);
	    
	    $time = $pars[0]*$deltaT + $timeTogetherStart0;
	    	    
	    $X[$dataNum] = $pars[1];
	    $Y[$dataNum] = $pars[2];
	    $time[$dataNum] = $time;
	    	
	    $timeEnd[$fileNum]=$time;
	    
	    $dataNum++;
	}    		 
    }
    close(IN);
    
    if($fileNum==1){
	$timeTogetherEnd=$timeEnd[$fileNum];
    } elsif ($timeEnd[$fileNum]<$timeTogetherEnd){
	$timeTogetherEnd=$timeEnd[$fileNum];
    }
    
    ###### Reading: Done
    
    ###### Only those data point should use for the calculetion of the statistics, which has enough real measured point around
    my @avrt=();
    my @avrx=();
    my @avry=();
    my @avrgood=();
      
    my $sigma = 2;	#1
    my $j=1;
    my $gaussLimit=0.001;
    my $i=0;
      
    while($i<=$#X){
	    if($SmoothTheDataFunctions==1){
	            my $avr_x = gauss (0, $sigma) * $X[$i];  
	            my $avr_y = gauss (0, $sigma) * $Y[$i];
		    $j=1;
		    my $gauss=gauss ($j, $sigma);
	    	    my $gaussSum = gauss (0, $sigma);
		    while($gauss>$gaussLimit){
		        if($i-$j>=0){
			    $avr_x += $gauss*( $X[$i-$j]);
			    $avr_y += $gauss*( $Y[$i-$j]);
	    		    $gaussSum += $gauss;
	    		}
	    		if($i+$j<$dataNum){
			    $avr_x += $gauss*( $X[$i+$j]);
			    $avr_y += $gauss*( $Y[$i+$j]);
	    		    $gaussSum += $gauss;
	    		}
			$j++;
			$gauss=gauss ($j, $sigma)
		    }
			push @avrt, sprintf("%d", round($time[$i])); #$avr_t/$gaussSum;
			push @avrx, $avr_x/$gaussSum;
			push @avry, $avr_y/$gaussSum;
			push @avrgood, 1;
    	    } else {
			push @avrt, sprintf("%d", round($time[$i]));
			push @avrx, $X[$i];
			push @avry, $Y[$i];
    			push @avrgood, 1;
	    }
	    
    	    $i++;
    }
    print "TEST: Converting functions: DONE\n"; #test
    
    #### Free arrays to prevent Out of memory
    @time=();@X=();@Y=();

    my @avrt_sec=();
    for(my $k=0; $k<$#avrt+1; $k++){
	$avrt_sec[$k]=$avrt[$k]/100.0;
    }
							  
															    
    my $timeSTART_ = $avrt[0];
    my $timeEND_ = $avrt[$#avrt];
    
    my @dXdT_ = Derivative1(\@avrt_sec,\@avrx);
    my @dYdT_ = Derivative1(\@avrt_sec,\@avry);

    my @d2XdT2_ = Derivative2(\@avrt_sec,\@avrx);
    my @d2YdT2_ = Derivative2(\@avrt_sec,\@avry);

    my $outputFile1=$OUTtrajdir."/".$datFile;
    open(OUT1, ">$outputFile1") || die ("Error: cannot write to $outputFile1, make directory: OUTtraj\n");
    print OUT1 "#t(centisec)\tX(m)\tY(m)\tVX(m/s)\tVY(m/s)\tAX(m/s2)\tAY(m/s2)\tgooddata\tuseforstat\n";

    for(my $k=0; $k<$#avrt+1; $k++){
	$time=$avrt[$k];
	
	$X_t{$time."_".$fileNum}=$avrx[$k];
	$Y_t{$time."_".$fileNum}=$avry[$k];
	$dXdT_t{$time."_".$fileNum}=$dXdT_[$k];
	$dYdT_t{$time."_".$fileNum}=$dYdT_[$k];
	$d2XdT2_t{$time."_".$fileNum}=$d2XdT2_[$k];
	$d2YdT2_t{$time."_".$fileNum}=$d2YdT2_[$k];
	$gooddata_t{$time."_".$fileNum}=1;
	$useforstat_t{$time."_".$fileNum}=1;
	printf OUT1 "%d\t%f\t%f\t%f\t%f\t%f\t%f\t%d\t%d\n",
	    $time,  $X_t{$time."_".$fileNum}, $Y_t{$time."_".$fileNum},
		    $dXdT_t{$time."_".$fileNum}, $dYdT_t{$time."_".$fileNum},
		    $d2XdT2_t{$time."_".$fileNum}, $d2YdT2_t{$time."_".$fileNum},
		    $gooddata_t{$time."_".$fileNum}, $useforstat_t{$time."_".$fileNum};
    }
    close(OUT1);
}

if($printForCuda==1){
#### PRINT OUT DATA INPUT FILE FOR CUDA PROGRAM
    my $outputFile2=$OUTdatadir."/pID_".$pID{1}."_pID_".$pID{2};
    open(OUT2, ">$outputFile2") || die ("Error: cannot write to $outputFile2, make directory: OUT\n");

    for($time=$timeTogetherStartFIXED; $time<=$timeTogetherEndFIXED; $time+=$deltaT){
	printf OUT2 "%d\t", $time;
	my $vi = vectorAbs ($dXdT_t{$time."_1"}, $dYdT_t{$time."_1"});
	my $vj = vectorAbs ($dXdT_t{$time."_2"}, $dYdT_t{$time."_2"});
	my $vix=0; my $viy=0;
	if($vi>0){
	    $vix = $dXdT_t{$time."_1"}/$vi;
	    $viy = $dYdT_t{$time."_1"}/$vi;
	}
	my $vjx=0; my $vjy=0;
	if($vj>0){
	    $vjx = $dXdT_t{$time."_2"}/$vj;
	    $vjy = $dYdT_t{$time."_2"}/$vj;
	}
	printf OUT2 "%.4f\t%.4f\t", $vix, $viy;
	printf OUT2 "%.4f\t%.4f\n", $vjx, $vjy;
    }
}
