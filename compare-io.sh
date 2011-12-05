#!/bin/bash

IO_EXPRESSIONS=(
write_bw

io_wkB_s
io_w_s
io_wrqm_s

io_rkB_s
io_r_s
io_rrqm_s

io_avgrq_sz
io_avgqu_sz
io_await
io_svctm
io_util

cpu_user
cpu_nice
cpu_system
cpu_iowait
cpu_steal
cpu_idle
)

for e in ${IO_EXPRESSIONS[*]}
do
	./compare.rb -e $e "$@"
	echo
done
