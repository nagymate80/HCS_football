#!/usr/bin/perl -w
$|++;
#
# combine tracks with the output of the cude script 
# Note: the script was tested and run on
# linux (Ubuntu, 18.04.2 LTS (Bionic Beaver), 4.15.0-43-generic) using
# perl 5, version 26, subversion 1 (v5.26.1) built for x86_64-linux-gnu-thread-multi
#
# author: Mate Nagy
####################################################################################################################
use strict;
use warnings;

use Math::Derivative qw(Derivative1 Derivative2);
use Math::Trig ':pi';
 
my $deltaT=10; #### in centisecs! !!!!!!!!!!!
my $SmoothTheDataFunctions=0;


my $dataNumMAX=27717;	#### NUMBER OF DATA POINTS TO ANALYS

my $timeWIN=400;
my $timeTogetherStart0 = 1000000;  
my $timeTogetherStartFIXED  ;
my $timeTogetherEndFIXED   ;

my $TEST=0;
my $CalcCROSSCOR=0;	#for testing do not calculate crosscorrelation

my $distMAXtocalcCrosscor=1000;		#100 #TEST_PUBLIC_DATA

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
my $cudaDir = shift @ARGV;

my $line;
my @datFiles;
opendir (directory_handle, $INdatadir) or die "Unable to open directory: $!";
while (my $file_name = readdir(directory_handle)) {
    if (length($file_name) >2) {
	push @datFiles, $file_name;
    }
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
    my $timeStartZero;
    while($line=<IN>){
	# skip comment lines and empty lines
	if(($line!~/^\s*\#/)&&($line!~/^\s*$/)){
	    chomp $line;
	    my @pars = split (' ', $line);
	    
	   if($dataNum<=$dataNumMAX){
	    
	    $time = $pars[0]*$deltaT + $timeTogetherStart0;
	    	    
	    $X[$dataNum] = $pars[1];
	    $Y[$dataNum] = $pars[2];
	    $time[$dataNum] = $time;
	
	    $timeEnd[$fileNum]=$time;
	    
	    $dataNum++;
	   }
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
    }

}


my $dStep=0.5;
my %ds=();

my $corStep=0.01;
my %cors=();


my $tauStep=1;
my %taus=();

my $dirStep=5.0; ### Angle
my %dirs=();

my %times=();

my %d_cor=();
my %d_tau=();
my %tau_cor=();
my %d_dir0=();
my %d_dirT=();

my $corMIN = 0.9;	#FOR d_tau
my $dMAX = 10;		#FOR tau_cor

my $tauMAX=4;

my %leadMinusFollow_i=();
my %lead_i=();
my %follow_i=();
my %leadFollow_i_j=();
my %lF_t_i_j=();

my %clust_num=();

my %inter_time = ();
my %topleader_time = ();


#### PRINT OUT DATA with the data read from OUTPUT FILE FROM CUDA PROGRAM

 for(my $f1=1; $f1<=$#datFiles+1; $f1++){
  for(my $f2=1; $f2<=$#datFiles+1; $f2++){
   print $cudaDir."/".$INdatadir."_1/pID_".$pID{$f1}."_pID_".$pID{$f2}."\n";
   if(-e $cudaDir."/".$INdatadir."_1/pID_".$pID{$f1}."_pID_".$pID{$f2}){

    my $OUTdatadir="OUTcuda/".$INdatadir;
    unless(-e $OUTdatadir or mkdir $OUTdatadir) {
    	die "Unable to create $OUTdatadir";
    }

    my $outputFile2=$OUTdatadir."/pID_".$pID{$f1}."_pID_".$pID{$f2};
    open(OUT2, ">$outputFile2") || die ("Error: cannot write to $outputFile2, make directory: OUT\n");

   for(my $run=1; $run<=1; $run++){
    my $CUDAdatadir=$cudaDir."/".$INdatadir."_".$run;
    my $cudaFile=$CUDAdatadir."/pID_".$pID{$f1}."_pID_".$pID{$f2};
    open(IN, "<$cudaFile") || die ("Error: cannot read from $cudaFile\n");
    
    my $lineNum=0;
    while($line=<IN>){
	# skip comment lines and empty lines
	if(($line!~/^\s*\#/)&&($line!~/^\s*$/)){
	    chomp $line;
	    my @pars = split (' ', $line);
	    $time = $pars[0];
	    my $maxCor = $pars[1];
	    my $maxTau = $pars[2];
	    if($lineNum==0){
		print OUT2 "#t(centisec)\tXi(m)\tYi(m)\tXj(m)\tYj(m)\tVXi(m/s)\tVYi(m/s)\tVXj(m/s)\tVYj(m/s)\tdij(m)\tmaxCor\tmaxTau(s)\tXj(t+tau)\tYj(t+tau)\n";
		$lineNum++;
	    }
	 printf OUT2 "%d\t", $time;
	    if(!defined $times{$time}){ $times{$time}=1; }

	 if( (defined $dXdT_t{$time."_".$f1}) && (defined $dXdT_t{$time."_".$f2})){
	
	    my $vi = vectorAbs ($dXdT_t{$time."_".$f1}, $dYdT_t{$time."_".$f1});
	    my $vj = vectorAbs ($dXdT_t{$time."_".$f2}, $dYdT_t{$time."_".$f2});
	    my $vix=0; my $viy=0;
	    if($vi>0){
		$vix = $dXdT_t{$time."_".$f1};
		$viy = $dYdT_t{$time."_".$f1};
	    }
	    my $vjx=0; my $vjy=0;
	    if($vj>0){
	        $vjx = $dXdT_t{$time."_".$f2};
	        $vjy = $dYdT_t{$time."_".$f2};
	    }

	    my $dij = vectorAbs ($X_t{$time."_".$f1}-$X_t{$time."_".$f2}, $Y_t{$time."_".$f1}-$Y_t{$time."_".$f2});
	    
	    my $dBin = round($dij/$dStep) * $dStep;
	    my $corBin = round($maxCor/$corStep) * $corStep;
	    my $tauBin = abs(round($maxTau/100.0/$tauStep) * $tauStep);
	    
	    
	    if($corBin>0){
		$d_cor{$dBin."_".$corBin}++;
		if($corBin>=$corMIN){
		    $d_tau{$dBin."_".$tauBin}++;
		}
		if($dBin<=$dMAX){
		    $tau_cor{$tauBin."_".$corBin}++;
		}
		if(!defined $cors{$corBin}){ $cors{$corBin}=1; }
		if(!defined $ds{$dBin}){ $ds{$dBin}=1; }
		if(!defined $taus{$tauBin}){ $taus{$tauBin}=1; }
	    }

	    printf OUT2 "%.4f\t%.4f\t", $X_t{$time."_".$f1}, $Y_t{$time."_".$f1};
	    printf OUT2 "%.4f\t%.4f\t", $X_t{$time."_".$f2}, $Y_t{$time."_".$f2};
	    printf OUT2 "%.4f\t%.4f\t", $vix, $viy;
	    printf OUT2 "%.4f\t%.4f\t", $vjx, $vjy;
	    printf OUT2 "%.4f\t%.4f\t%.4f\t", $dij, $maxCor, $maxTau/100;
	    my $time2 = $time + int($maxTau);
	    my $time3 = $time - int($maxTau);
	    my $dijT;
	    my $dirT;	my $dir0;
	    if(($maxCor>0) && (defined $X_t{$time2."_".$f2})){
		printf OUT2 "%.4f\t%.4f\n", $X_t{$time2."_".$f2}, $Y_t{$time2."_".$f2};
		if( (abs($tauBin) <= $tauMAX) && ($corBin >= $corMIN) ){
		    if($maxTau>=0){
		    	$dijT = vectorAbs ($X_t{$time."_".$f1}-$X_t{$time2."_".$f2}, $Y_t{$time."_".$f1}-$Y_t{$time2."_".$f2});
		    	$dirT = atan2 ($Y_t{$time."_".$f1}-$Y_t{$time2."_".$f2}, $X_t{$time."_".$f1}-$X_t{$time2."_".$f2});
		    	$dir0 = atan2 ($Y_t{$time."_".$f1}-$Y_t{$time."_".$f2},  $X_t{$time."_".$f1}-$X_t{$time."_".$f2});
			if($dij<$dMAX){
			    
			    $leadMinusFollow_i{$pID{$f1}}++;
			    $lead_i{$pID{$f1}}++;
			    $leadMinusFollow_i{$pID{$f2}}--;
			    $follow_i{$pID{$f2}}++;
			    $leadFollow_i_j{$pID{$f1}."_".$pID{$f2}}++;
			    $lF_t_i_j{$time."_".$pID{$f1}."_".$pID{$f2}}++;
			}
			    
		    } else {
			$dijT = vectorAbs ($X_t{$time."_".$f2}-$X_t{$time3."_".$f1}, $Y_t{$time."_".$f2}-$Y_t{$time3."_".$f1});
		    	$dirT = atan2 ($Y_t{$time."_".$f2}-$Y_t{$time3."_".$f1}, $X_t{$time."_".$f2}-$X_t{$time3."_".$f1});
		    	$dir0 = atan2 ($Y_t{$time."_".$f2}-$Y_t{$time."_".$f1},  $X_t{$time."_".$f2}-$X_t{$time."_".$f1});

			if($dij<$dMAX){

			    $leadMinusFollow_i{$pID{$f2}}++;
			    $lead_i{$pID{$f2}}++;
			    $leadMinusFollow_i{$pID{$f1}}--;
			    $follow_i{$pID{$f1}}++;
			    $leadFollow_i_j{$pID{$f2}."_".$pID{$f1}}++;
			    $lF_t_i_j{$time."_".$pID{$f2}."_".$pID{$f1}}++;
		          }
		    }
		    my $dir0Bin = round($dir0/pi*180.0/$dirStep) * $dirStep;
		    my $dirTBin = round($dirT/pi*180.0/$dirStep) * $dirStep;
		    my $dTBin = round($dijT/$dStep) * $dStep;
		    
		    $d_dir0{$dBin."_".$dir0Bin}++;
		    $d_dirT{$dTBin."_".$dirTBin}++;
		    
		    if(!defined $ds{$dTBin}){ $ds{$dTBin}=1; }
		    if(!defined $dirs{$dir0Bin}){ $dirs{$dir0Bin}=1; }
		    if(!defined $dirs{$dirTBin}){ $dirs{$dirTBin}=1; }
		    
		    $inter_time{$time}++;
		}
	    } else {
		printf OUT2 "NaN\tNaN\n";
	    }
	 } else {
	    printf OUT2 "NaN\t"*12;
	    printf OUT2 "NaN\n";
	 }
        } else {
    	    chomp $line;
    	    printf OUT2 $line."\n";

        }
    }
    close(IN);
   }
    close(OUT2);
}}}


#### PRINT OUT d Cor

 my $outputFile3 = "OUTd_cor/".$INdatadir;
 open(OUT3, ">$outputFile3") || die ("Error: cannot write to $outputFile3, make directory: OUTd_cor\n");
 printf OUT3 "#d(m)\tcor\thist\n";
 
 my @cors = sort { $a <=> $b } keys (%cors);
 my @ds = sort { $a <=> $b } keys (%ds);

foreach my $cor (@cors){
 foreach my $d (@ds){
    if(defined $d_cor{$d."_".$cor}){
	printf OUT3 $d."\t".$cor."\t".$d_cor{$d."_".$cor}."\n";
    } else {
	printf OUT3 "$d\t$cor\t0\n";
    }
 }
 printf OUT3 "\n";
}
close(OUT3);


#### PRINT OUT d tau

 $outputFile3 = "OUTd_tau/".$INdatadir;
 open(OUT3, ">$outputFile3") || die ("Error: cannot write to $outputFile3, make directory: OUTd_tau\n");
 printf OUT3 "#corMIN = $corMIN\n";
 printf OUT3 "#d(m)\ttau\thist\n";
 
 my @taus = sort { $a <=> $b } keys (%taus);

foreach my $d (@ds){
 foreach my $tau (@taus){
    if(defined $d_tau{$d."_".$tau}){
	printf OUT3 $d."\t".$tau."\t".$d_tau{$d."_".$tau}."\n";
    } else {
	printf OUT3 "$d\t$tau\t0\n";
    }
 }
 printf OUT3 "\n";
}
close(OUT3);


