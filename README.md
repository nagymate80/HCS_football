# HCS_football
Calculation of Highly Correlated Segments (HCS) from players positional data
(given in the directory: 0_SampleData)

#########################################################################################
Pipeline to run the scripts which are modular and calculate only part of 
the analysis. (Author: Mate Nagy, this file was created 2019/03/12)
##########################################################################################

- 1_run_PerlForCuda:

this script calculates input files for the cuda script.
its output is in OUT/<dir_name> in case of the sample dataset:
OUT/sample_1

Important parameters to set: $deltaT is the parameter for the time 
resolution, in centiseconds. This value should be an integer number

- 2_cudaCalculation:

this script calculates the cross-correlation. Its input should be the 
directory with the files as the output from the previous script.

Its output files are in OUT/  correlation values for all defined time 
delays and timesteps. In OUTmax for each timestep the highest correlation 
and the corresponding time delay is given

Important paratemers to set are in the heading. The exact number of frames 
(number of time steps) needs to be given. The time resolution of the data, 
how frequently the correlcation should be calculated, what is the range 
for the time delay, and the length of the time window for the segments 

- 3_combineTrackWithCudaResults:

runs calculation on the statistics as an input which is the output of the  

cross-correlation cuda script.
Outputs some of the pooled data.

- 4_getHCS:

calculates HCS statistics from 2 inputs: the tracks (positional data of 
the players) and the output of the cross-correlation cuda script. 

Outputs the HCS in time and for each pair with the corresponding 
correlation value and the time delay into the output file InterAll. 

Outputs also the histogram of HCS timing for each pairs.

Outputs a table including all the number of HCS.

- 5_summary:

calculates summary from the HCS metric (last output of the previous 
script) as an input file.

Outputs HCS statistics, and aggregated data for players

- 6_normalise_players:

normalise the distributions based on the data spent on the field

Input the player output of the previous script

Output normalised data
