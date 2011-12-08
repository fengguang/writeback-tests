#!/bin/sh

for dir
do

plot() {
data=$1
suffix=$2
gnuplot <<EOF
set xlabel "time (s)"

set size 1
set terminal pngcairo size ${width:-1000}, ${height:-600}
set terminal pngcairo size ${width:-1280}, ${height:-800}

set grid

set output "balance_dirty_pages-bandwidth$suffix.png"
set ylabel "bandwidth (MB/s)"
plot "$data-bw" using 1:(\$2/1024) with      points pt 5 ps 0.7 title "write bandwidth", \
     "$data-bw" using 1:(\$3/1024) with lines lw 2 lc rgbcolor "gold" title "avg bandwidth", \
     "$data-bw" using 1:(\$6/1024) with     points pt 7 ps 0.4 lc rgbcolor "greenyellow" title "task ratelimit", \
     "$data-bw" using 1:(\$5/1024) with steps lw 2 lc rgbcolor "blue" title "dirty ratelimit"
     # "$data-bw" using 1:(\$8/1024) with   linespoints pt 3 ps 0.5 lc rgbcolor "sandybrown" title "dirty bandwidth", \

unset grid

#  2  limit,
#  3  goal,
#  4  dirty,
#  5  bdi_goal,
#  6  bdi_dirty,
#  7  base_bw,     /* base throttle bandwidth */
#  8  task_bw,     /* task throttle bandwidth */
#  9  dirtied,
#  10 dirtied_pause,
#  11 paused       /* ms */
#  12 pause,       /* ms */
#  13 period,
#  14 think,

set output "balance_dirty_pages-pages$suffix.png"
set ylabel "memory (MB)"
set y2label "ratelimit (MB/s)"
set ytics nomirror
set y2tics
set logscale y2 2
plot \
     "$data" using 1:(\$5/256) with linespoints pt 6 ps 0.9 lc rgbcolor "gray"   title "bdi setpoint", \
     "$data" using 1:(\$6/256)  with linespoints pt 7 ps 0.6 lc rgbcolor "salmon" title "bdi dirty", \
     "$data" using 1:(\$2/256) with linespoints pt 4 ps 0.9 lc rgbcolor "orange" title "limit", \
     "$data" using 1:(\$3/256)  with linespoints pt 4 ps 0.9 lc rgbcolor "web-green"   title "setpoint", \
     "$data" using 1:(\$4/256)  with      points      lw 1.2 lc rgbcolor "orange-red" title "dirty", \
     "$data" using 1:(\$8/1024) axis x1y2 with   points pt 3 ps 0.5 lw 1.5 lc rgbcolor "greenyellow" title "task ratelimit", \
     "$data-bw" using 1:(\$7/1024) axis x1y2 with   points pt 3 ps 0.6 lc rgbcolor "skyblue" title "balanced dirty ratelimit", \
     "$data" using 1:(\$7/1024) axis x1y2 with   steps lw 2 lc rgbcolor "blue" title "dirty ratelimit"

set output "balance_dirty_pages-pause$suffix.png"
set ylabel "pause time (ms)"
set y2label "dirtied pages"
set ytics nomirror
set y2tics
unset logscale y2
plot "$data" using 1:11 axis x1y1 with points pt 5 ps 1.0 lc rgbcolor "orange"     title "paused", \
     "$data" using 1:12 axis x1y1 with points pt 7 ps 0.6 lc rgbcolor "red"  title "pause", \
     "$data" using 1:10 axis x1y2 with points pt 1 ps 0.5 lw 1.5 lc rgbcolor "skyblue"    title "target dirtied", \
     "$data" using 1:9  axis x1y2 with points pt 2 ps 0.5 lw 1.5 lc rgbcolor "dark-turquoise"    title "dirtied"

EOF
}

cd $dir

[[ -f trace.bz2 ]] || exit

trace=trace-balance_dirty_pages

bzcat trace.bz2 | grep -F balance_dirty_pages | awk '/(dd|tar|fio)-[0-9]+/{print $1; exit}'| sed 's/[^0-9]//g' > fio-pid
bzcat trace.bz2 | grep -F balance_dirty_pages | awk '/<...>-[0-9]+/{print $1; exit}'| sed 's/[^0-9]//g' > more-pid

# dd=$(cat pid | cut -f1 -d' ')
# [[ -n "$dd" ]] || exit
for dd in $(cat pid fio-pid more-pid)
do
	bzcat trace.bz2 |\
		grep -- "-$dd \+\[" |\
		grep -c1 -F balance_dirty_pages && break
done
test $? = 0 || exit

bdi=$(bzcat trace.bz2 | grep -- "-$dd \+\[" | awk '/balance_dirty_pages/{print $6; exit}')
bzcat trace.bz2 | grep -E -- "-$dd +\[.* (balance_dirty_pages|bdi_dirty_ratelimit): bdi $bdi " > $trace-$dd

grep -F balance_dirty_pages $trace-$dd |\
	sed 's/^.*] //' |\
	sed 's/bdi [^ ]\+//' |\
	sed 's/[^0-9.-]\+/ /g' |\
	sed 's/\.\.\. *//' > $trace
grep -F bdi_dirty_ratelimit: $trace-$dd |\
	sed 's/^.*] //' |\
	sed 's/bdi [^ ]\+//' |\
	sed 's/[^0-9.-]\+/ /g' |\
	sed 's/\.\.\. *//' > $trace-bw

# width=1000
# width=1280
plot $trace

lines=$(wc -l $trace | cut -f1 -d' ')

# if [[ $lines -gt 600 ]]; then
# head -n 300 < $trace > $trace-rampup
# plot $trace-rampup -rampup
# 
# if [[ $lines -gt 3000 ]]; then
# tail -n 3000 < $trace > $trace-3000
# plot $trace-3000 -3000
# fi

if [[ $lines -gt 800 ]]; then

tail -n 500 $trace-$dd |\
	grep -F balance_dirty_pages |\
	sed 's/^.*\] //' |\
	sed 's/bdi [^ ]\+//' |\
	sed 's/[^0-9.-]\+/ /g' |\
	sed 's/\.\.\. *//' > $trace-500

tail -n 500 $trace-$dd |\
	grep -F bdi_dirty_ratelimit: |\
	sed 's/^.*\] //' |\
	sed 's/bdi [^ ]\+//' |\
	sed 's/[^0-9.-]\+/ /g' |\
	sed 's/\.\.\. *//' > $trace-500-bw

plot $trace-500 -500
fi

if [[ $lines -ge 800 ]]; then
old_width=$width
width=8000
plot $trace +
rm balance_dirty_pages-bandwidth+.png
width=$old_width
# rm balance_dirty_pages-bw+.png
# [[ $NR_TASKS -lt 5 ]] && rm balance_dirty_pages-bw.png
fi

rm $trace*

cd ..
done
