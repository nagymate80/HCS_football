#!/usr/bin/gnuplot
#set encoding iso_8859_1

#set title ""

set xlabel "d (m)"
set ylabel "cor"
set zlabel "hist."
set cblabel "hist."


set palette color positive



set xrange [0:55]
set yrange [0.9:1.005]

set title "sample"
plot "sample" using 1:2:3 with image notitle
pause -1 "Press enter!"


set term png transparent enhanced font "helvetica,12"
set out "d_cor.png"
replot
