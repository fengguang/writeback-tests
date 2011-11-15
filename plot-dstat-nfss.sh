#!/bin/bash

dstat=dstat-nfss

for dir
do

# iostat -kx 1
# avg-cpu:  %user   %nice %system %iowait  %steal   %idle
#            0.75    0.00    6.36   18.20    0.00   74.69
# 		1	2	3	4	5	6

# Device:         rrqm/s   wrqm/s     r/s     w/s    rkB/s    wkB/s avgrq-sz avgqu-sz   await  svctm  %util
# sda               0.00     0.00    0.00  136.63     0.00 63065.35   923.13   143.09 1416.26   7.28  99.41
# 1			2	3	4	5	6	7	8	9	10	11	12

plot() {
dstat=$1
start_time=$2
suffix=$3
gnuplot <<EOF
set xlabel "time (s)"

set size 1
set terminal pngcairo size ${width:-1280}, 800
set terminal pngcairo size ${width:-1000}, 600

set grid

set datafile separator ","

set output "$dstat-bw$suffix.png"
set ylabel "throughput (MB/s)"
plot \
	"$dstat" using (\$1 - $start_time):(\$10/1048576) with impulses lc rgbcolor "green" title "net recv MB/s", \
	"$dstat" using (\$1 - $start_time):(\$9/1048576) with points pt 7 lc rgbcolor "red" title "disk write MB/s"

unset grid

EOF
}

cd $dir

test -s $dstat || exit

start_time=$(awk -F',' '{ if ($1 > 0) { print $1; exit } }' $dstat)

plot $dstat $start_time

# lines=$(wc -l iostat-disk | cut -f1 -d' ')

# if [[ $lines -gt 100 ]]; then
# tail -n 50 < iostat-disk > iostat-disk-50
# tail -n 50 < iostat-cpu > iostat-cpu-50
# plot iostat-disk-50 iostat-cpu-50 -50
# fi

# if [[ $lines -ge 100 ]]; then
# width=3200
# plot $trace iostat-disk iostat-cpu +
# fi

cd -

done
