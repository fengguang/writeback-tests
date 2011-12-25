#!/bin/bash

run_fio() {
	local job_file=$job
	[[ -f $job_file ]] || job_file=../$job
	[[ -f $job_file ]] || job_file=$BASE_DIR/$job

	# --debug=io,file 
	fio $job_file 2>&1 > fio.log &
	pid=$!

	wait $pid
}

run_dd() {
	for i in `seq $nr_dd`
	do
		for dev in $bdevs
		do
			mnt=$MNT/$(basename $dev)
			rm -f $mnt/zero-$i
			# ulimit -m $((i<<10))
			dd bs=$bs if=/dev/zero of=$mnt/zero-$i &
			echo $! >> pid
			# sleep 5
		done
	done

	sleep $RUNTIME
}

run_test() {

	fs_options
	destroy_devices
	make_md
	make_fs
	mount_fs

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
	reboot_kexec
}
