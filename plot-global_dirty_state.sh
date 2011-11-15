#!/bin/sh

for dir
do

#	dd-2617  [000]    17.535224: global_dirty_state: dirty=430 writeback=0 unstable=0 bg_thresh=69711 thresh=139423 gap=138993

plot() {
data=$1
suffix=$2
gnuplot <<EOF
set xlabel "time (s)"

set size 1
set terminal pngcairo size ${width:-1280}, 800
set terminal pngcairo size ${width:-1000}, 600
set terminal pngcairo size ${width:-1280}, ${height:-800}

set output "global_dirty_state$suffix.png"
set ylabel "memory (MB)"
plot \
     "$data" using 1:(\$7/256) with linespoints pt 4 ps 0.6 lc rgbcolor "orange-red" title "dirty limit", \
     "$data" using 1:(\$6/256) with linespoints pt 4 ps 0.6 lc rgbcolor "orange" title "dirty thresh", \
     "$data" using 1:(\$5/256) with linespoints pt 3 ps 0.6 lc rgbcolor "grey" title "background thresh", \
     "$data" using 1:(\$2/256) with linespoints pt 5 ps 0.6 lc rgbcolor "red" lw 1 title "dirty", \
     "$data" using 1:(\$3/256) with linespoints pt 7 ps 0.6 lc rgbcolor "green" lw 1 title "writeback", \
     "$data" using 1:(\$4/256) with linespoints pt 6 ps 0.6 lc rgbcolor "blue" lw 1 title "unstable", \
     "$data" using 1:((\$2+\$3+\$4)/256) with linespoints pt 1 ps 0.5 lc rgbcolor "magenta" lw 0.8 title "dirty+writeback+unstable"

set grid
set output "global_dirtied_written$suffix.png"
set ylabel "memory (MB)"
plot \
     "$data" using 1:(\$8/256)  with linespoints pt 7 ps 0.6 lc rgbcolor "red"          title "dirtied", \
     "$data" using 1:(\$9/256) with linespoints pt 5 ps 0.6 lc rgbcolor "spring-green" title "written"
EOF
}

cd $dir

[[ -f trace || -f trace.bz2 ]] || exit

trace=trace-global_dirty_state

for dd in $(cat pid)
do
	bzcat trace.bz2 | grep -- "$dd \+\[" |\
		grep -F global_dirty_state |\
		sed 's/bdi [^ ]\+//' |\
		sed 's/.*\]//g' |\
		sed 's/[^0-9.-]\+/ /g' > $trace
	test -s $trace && break
		# grep -vF 'bdi 0:15:' |\
done
test -s $trace || { rm $trace; exit; }

bzcat trace.bz2 | grep -F "flush-" |\
	grep -F "global_dirty_state" |\
	sed 's/.*\]//g' |\
	sed 's/[^0-9.-]\+/ /g' > $trace-flusher
	# grep -vF 'bdi 0:15:' |\

rm -f write-bandwidth
plot $trace-flusher

lines=$(wc -l $trace | cut -f1 -d' ')

if [[ $lines -gt 1000 ]]; then
	# head -n 500 < $trace > $trace-rampup
	# plot $trace-rampup -rampup
 
	tail -n 500 < $trace > $trace-500
	plot $trace-500 -500
fi

# if [[ $lines -ge 300 ]]; then
# width=12800
# plot $trace +
# fi

# it can be big
rm $trace

cd ..
done
