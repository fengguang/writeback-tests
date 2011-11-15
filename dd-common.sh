#!/bin/bash

run_fio() {
	fio $BASE_DIR/$job 2>&1 > fio.log &
	pid=$!

	sleep 10
	pidof fio > pid

	(sleep 3600 && killall fio)&
	# echo t > /proc/sysrq-trigger

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

	destroy_devices
	make_md
	fs_options
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

	sync
	umount /fs/*
	reboot
	exit
}
