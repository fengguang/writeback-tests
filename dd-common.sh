#!/bin/bash

run_fio() {
	local job_file=$job
	[[ -f $job_file ]] || job_file=../$job
	[[ -f $job_file ]] || job_file=$BASE_DIR/$job

	# --debug=io,file 
	fio $job_file 2>&1 > fio.log &
	pid=$!

	sleep 100; ps -eo pid,tid,class,rtprio,ni,pri,psr,pcpu,stat,wchan:48,comm  > ps
	sleep 1;   ps -eo pid,tid,class,rtprio,ni,pri,psr,pcpu,stat,wchan:48,comm >> ps
	sleep 1;   ps -eo pid,tid,class,rtprio,ni,pri,psr,pcpu,stat,wchan:48,comm >> ps
	sleep 1;   ps -eo pid,tid,class,rtprio,ni,pri,psr,pcpu,stat,wchan:48,comm >> ps
	# echo w > /proc/sysrq-trigger
	# blktrace /dev/sda -w1

	wait $pid
}

run_dd() {
	local bs_opt
	# dd defaults to bs=512 which could make it CPU bound
	[[ dd_opt =~ 'bs=' ]] || bs_opt="bs=${bs:-64k}"

	for i in `seq $nr_dd`
	do
		for dev in $bdevs
		do
			mnt=$MNT/$(basename $dev)
			rm -f $mnt/zero-$i
			# ulimit -m $((i<<10))
			dd $bs_opt $(echo $dd_opt | tr : ' ') if=/dev/zero of=$mnt/zero-$i &
			echo $! >> pid
			# sleep 5
		done
	done

	sleep $((RUNTIME/5)); ps -eo pid,tid,class,rtprio,ni,pri,psr,pcpu,stat,wchan:48,comm  > ps
	sleep $((RUNTIME/5)); ps -eo pid,tid,class,rtprio,ni,pri,psr,pcpu,stat,wchan:48,comm >> ps
	sleep $((RUNTIME/5)); ps -eo pid,tid,class,rtprio,ni,pri,psr,pcpu,stat,wchan:48,comm >> ps
	sleep $((RUNTIME/5)); ps -eo pid,tid,class,rtprio,ni,pri,psr,pcpu,stat,wchan:48,comm >> ps
	sleep $((RUNTIME/5));
	# echo w > /proc/sysrq-trigger; blktrace /dev/sda -w1
}

run_test() {

	fs_options
	destroy_devices
	make_md
	make_fs
	mount_fs

	touch .live
	log_start

	enable_tracepoints

	run_$1

	log_end

	while pidof dd
	do
		killall -9 dd
	done

	rm -f $MNT/*/zero-*

	post_processing

	wait # perf may be slow: too many xfs events
	umount /fs/*
	sync
	rm .live
	reboot_kexec
}
