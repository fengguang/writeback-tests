#!/bin/bash

trap "" INT
umask 002

cd $(dirname $0)
BASE_DIR=$(pwd)
PATH=$PATH:$BASE_DIR
cd -

plot_dir() {
	pushd $1 || return

	plot-balance_dirty_pages.sh . &
	plot-global_dirty_state.sh . &
	plot-bdi_dirty_state.sh . &
	plot-writeback_single_inode.sh . &
	plot-task-bw.sh . &
	# plot-vmstat.sh .

	if [[ `basename $PWD` =~ ^nfs ]]; then
		plot-nfs-commit.sh . &
		plot-dstat-nfss.sh . &
	else
		plot-iostat.sh . &
	fi

	popd

	trap - INT
	wait
	trap "" INT
}

[[ $1 ]] && {
	while [[ -d $1 ]];
	do
		plot_dir $1
		shift
	done
	exit
}

while true
do
	for file in $BASE_DIR/plot_jobs/*
	do
		if [[ -f "$file" ]]; then
			dir=$(<$file)
			rm $file || continue  # someone else took the job?
			plot_dir $dir
		fi
	done

	trap - INT
	sleep 100
	trap "" INT
done
