#!/bin/bash

enable_tracepoints() {

	echo 1 > /debug/tracing/tracing_on

	echo 1 > /debug/tracing/events/writeback/balance_dirty_pages/enable
	echo 1 > /debug/tracing/events/writeback/bdi_dirty_ratelimit/enable
	echo 1 > /debug/tracing/events/writeback/global_dirty_state/enable

	echo 1 > /debug/tracing/events/writeback/writeback_single_inode/enable
	echo 1 > /debug/tracing/events/writeback/writeback_wait/enable
	echo 1 > /debug/tracing/events/writeback/writeback_start/enable
	echo 1 > /debug/tracing/events/writeback/writeback_written/enable
	echo 1 > /debug/tracing/events/writeback/writeback_exec/enable
	echo 1 > /debug/tracing/events/writeback/writeback_wake_background/enable

	# echo 1 > /debug/tracing/events/writeback/bdi_dirty_state/enable
	# echo 1 > /debug/tracing/events/writeback/task_io/enable

	# echo 1 > /debug/tracing/events/writeback/fdatawrite_range/enable

	# echo 1 > /debug/tracing/events/writeback/prop_norm_single/enable

	# echo 1 > /debug/tracing/events/btrfs/btrfs_ordered_extent_add/enable
	# echo 1 > /debug/tracing/events/btrfs/btrfs_ordered_extent_start/enable
	# echo 1 > /debug/tracing/events/btrfs/btrfs_finish_ordered_io/enable

	# echo 1 > /debug/tracing/events/rcu/enable
	# echo 1 > /debug/tracing/events/block/block_rq_complete/enable
	# echo 1 > /debug/tracing/events/workqueue/enable

	if [[ $fstype = 'nfs' ]]; then
		echo 1 > /debug/tracing/events/nfs/nfs_commit_unstable_pages/enable
		echo 1 > /debug/tracing/events/nfs/nfs_commit_release/enable
	fi
}

trace_tab() {
	grep -o "[0-9.]\+: $1: .*" |\
	sed -e 's/bdi [^ ]\+//' \
	    -e 's/[^0-9.-]\+/ /g'
}

log_start() {
	IOSTAT_DISK=$(echo $devices | cut -f3 -d/ | tr -d [0-9])

	uname -a > kernel
	cat /sys/block/sd?/queue/scheduler > scheduler
	grep $MNT /proc/self/mountinfo > mountinfo

	cp /proc/vmstat vmstat-begin
	cp /proc/slabinfo slabinfo-begin
	cat /proc/self/mountstats > mountstats-begin

	# record dmesg progressively, so that we get some information
	# before the kernel is goes wrong
	killall klogd
	dmesg > dmesg
	cat /proc/kmsg >> dmesg &
	echo $! > pid-dmesg

	# collect-vmstat.sh $RUNTIME &
	# echo $! > pid-vmstat
	iostat -tkx 1 $RUNTIME > iostat &
	echo $! > pid-iostat
	dstat -Ta --output dstat 1 $RUNTIME &
	echo $! > pid-dstat
	if [[ $fstype = nfs ]]; then
		nfs_server=${devices%:*}
		ssh $nfs_server "mkfifo /tmp/dstat_fifo"
		ssh $nfs_server "dstat -Ta --output /tmp/dstat_fifo 1 $RUNTIME >/dev/null" &
		echo $! > pid-dstat-nfss
		ssh $nfs_server "cat /tmp/dstat_fifo" > dstat-nfss &
		echo $! > pid-cat-dstat-nfss
		ssh $nfs_server "cat /debug/tracing/trace_pipe | bzip2" > trace-nfss.bz2 &
		echo $! > pid-trace-nfss
	fi

	perf_events='writeback:*,block:*'
	[[ $fs_events ]] && perf_events+=",$fs_events"
	ulimit -n 100000
	mkfifo /tmp/perf_wait
	perf stat -x'	' -a -e "$perf_events" -o perf-stat cat /tmp/perf_wait &

	mkfifo /tmp/trace_fifo
	mkfifo /tmp/trace_fifo2
	tee /tmp/trace_fifo2 < /debug/tracing/trace_pipe > /tmp/trace_fifo &
	echo $! > pid-trace
	# tee /tmp/trace_fifo2 < /tmp/trace_fifo | bzip2 > trace.bz2 &
	bzip2 < /tmp/trace_fifo > trace.bz2 &
	grep -F "flush-" /tmp/trace_fifo2 |\
		trace_tab global_dirty_state > trace-global_dirty_state-flusher &
}

log_end() {
	echo 0 > /debug/tracing/tracing_on
	: > /tmp/perf_wait
	kill $(cat pid-*)
	kill $(cat pid)
	rm pid-*
	grep -h flush- /proc/*/comm | sort > bdi
	# echo 0 > /debug/tracing/events/writeback/enable
	# echo 0 > /debug/tracing/events/nfs/enable
	# echo 0 > /debug/tracing/tracing_on
	# cp /debug/tracing/trace trace
	cp /proc/vmstat vmstat-end
	cp /proc/slabinfo slabinfo-end
	chmod go+r slabinfo-*
	cat /proc/self/mountstats > mountstats-end
	grep . /sys/block/sd?/bdi/writeback_stats  > writeback_stats
	[ -s writeback_stats ] || rm writeback_stats
	[ -f /proc/lock_stat ] && cat /proc/lock_stat > lock_stat
	cp /proc/config.gz .
	find $MNT -type f \( -name zero-* -o -name f? \) | xargs ls -li > ls-files
	find $MNT -type f \( -name zero-* -o -name f? \) | xargs rm &
}

process_iostat() {
	avg=iostat-avg
	lines=$(grep -c avg-cpu iostat | cut -f1 -d' ')
	echo "avg-cpu:  %user   %nice %system %iowait  %steal   %idle" > $avg
	grep -A1 avg-cpu iostat | grep -F . | tail -n $((lines*2/3)) | avg.rb >> $avg
	echo >> $avg
	echo "Device:         rrqm/s   wrqm/s     r/s     w/s    rkB/s    wkB/s avgrq-sz avgqu-sz   await  svctm  %util" >> $avg
	grep ${IOSTAT_DISK:-sda} iostat | tail -n $((lines*2/3)) | avg.rb >> $avg

	grep -A1 avg-cpu iostat | grep -v '[a-z-]' > iostat-cpu
	grep ${IOSTAT_DISK:-sda} iostat > iostat-disk
}

process_dstat() {
	avg=dstat-avg
	lines=$(wc -l dstat | cut -f1 -d' ')
	grep writ dstat > $avg
	grep '[1-9]' dstat | tail -n $((lines*2/3)) | tr , ' ' | avg.rb >> $avg
}

post_processing() {
	cat /debug/tracing/trace | bzip2 >> trace.bz2

	if [[ $fstype = nfs ]]; then
		nfsstat -mc > nfsstat
	fi

	process_iostat
	process_dstat

	if (( $PLOT_IN_TESTBOX == 0 )); then
		sync
		mkdir -p $BASE_DIR/plot-jobs/
		plot_job=$BASE_DIR/plot-jobs/$(hostname)-$(date +'%F-%T')
		echo $PWD > $plot_job
		chmod g+w   $plot_job
	else
		$BASE_DIR/plot-all.sh .
	fi
}
