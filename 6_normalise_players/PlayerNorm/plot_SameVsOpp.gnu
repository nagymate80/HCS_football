#!/usr/bin/gnuplot


set xlabel "x"
set ylabel "y"


dx = 52.5
dy = 34




#set term png transparent enhanced



 f(x) = x

 set size ratio -1
 set xrange [0:3]
 set yrange [0:3]
 set ylabel "Same"
 set xlabel "Opp."
 set title "sample"
 plot "PlayerHCS_SameOpp_sample_Norm" u 27:4 w p ps 2 pt 7 notitle, f(x) lt 0 notitle
pause -1 "Press enter!"
 set term png
 set out "HCSBest_sample.png"
 replot
pause -1 "Press enter!"

