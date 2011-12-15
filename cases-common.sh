#!/bin/bash

make_dir() {
	config=$1
	job=$2
	dir=$(hostname)/$config/$fs-$job-$loop-$(</proc/sys/kernel/osrelease)

	[ -d $dir ] && return 1

	mkdir -p $dir
	cd $dir
}

fio_job() {
	job=$1
	make_dir fio $job || return
	run_test fio
}

jbod_12hdd() {

	devices="
	/dev/sdb1 /dev/sdb2
	/dev/sdc1 /dev/sdc2
	/dev/sdd1 /dev/sdd2
	/dev/sde1 /dev/sde2
	/dev/sdf1 /dev/sdf2
	/dev/sdg1 /dev/sdg2
	/dev/sdh1 /dev/sdh2
	/dev/sdi1 /dev/sdi2
	/dev/sdj1 /dev/sdj2
	/dev/sdk1 /dev/sdk2
	/dev/sdl1 /dev/sdl2
	/dev/sdm1 /dev/sdm2
	"

	local rw=$1
	local ioengine=$2
	local fallocate=$3
	local blocksize=$4

	job=fio_jbod_12hdd_${rw}_${ioengine}_${fallocate}_${blocksize}

	make_dir jbod_12hdd $job || return

	cat > $job <<EOF
[global]
runtime=$RUNTIME
rw=$rw
direct=0
ioengine=$ioengine
size=8G
blocksize=$blocksize
numjobs=1
fallocate=$fallocate
overwrite=0
create_sparse=1
invalidate=0
directory=$MNT
file_service_type=random:36

$(<$BASE_DIR/fio_jbod_12hdd_template)
EOF
	run_test fio
}

jbod_12hdd_randrw_4k()				{ jbod_12hdd randrw	sync	0	  4k;	}
jbod_12hdd_randrw_64k()				{ jbod_12hdd randrw	sync	0	 64k;	}
jbod_12hdd_randwrite_4k()			{ jbod_12hdd randwrite	sync	0	  4k;	}
jbod_12hdd_randwrite_64k()			{ jbod_12hdd randwrite	sync	0	 64k;	}
jbod_12hdd_mmap_randrw_4k()			{ jbod_12hdd randrw	mmap	0	  4k;	}
jbod_12hdd_mmap_randrw_64k()			{ jbod_12hdd randrw	mmap	0	 64k;	}
jbod_12hdd_mmap_randwrite_4k()			{ jbod_12hdd randwrite	mmap	0	  4k;	}
jbod_12hdd_mmap_randwrite_64k()			{ jbod_12hdd randwrite	mmap	0	 64k;	}
jbod_12hdd_fallocate_randrw_4k()		{ jbod_12hdd randrw	sync	1	  4k;	}
jbod_12hdd_fallocate_randrw_64k()		{ jbod_12hdd randrw	sync	1	 64k;	}
jbod_12hdd_fallocate_randwrite_4k()		{ jbod_12hdd randwrite	sync	1	  4k;	}
jbod_12hdd_fallocate_randwrite_64k()		{ jbod_12hdd randwrite	sync	1	 64k;	}
jbod_12hdd_fallocate_mmap_randrw_4k()		{ jbod_12hdd randrw	mmap	1	  4k;	}
jbod_12hdd_fallocate_mmap_randrw_64k()		{ jbod_12hdd randrw	mmap	1	 64k;	}
jbod_12hdd_fallocate_mmap_randwrite_4k()	{ jbod_12hdd randwrite	mmap	1	  4k;	}
jbod_12hdd_fallocate_mmap_randwrite_64k()	{ jbod_12hdd randwrite	mmap	1	 64k;	}


dd_job() {
	job=${nr_dd}dd
	[[ $bs != 4k ]] && job+=":bs=$bs"
	echo $job
}

thresh() {
	local dirty_thresh=$1
	local unit=$2
	local ndisk=${3:-1}
	local array=${4:-JBOD}

	local bits output_dir bg_dirty_thresh bg_name storage_prefix

	[[ $dirty_thresh =~ : ]] && {
		bg_dirty_thresh=${dirty_thresh##*:}
		dirty_thresh=${dirty_thresh%%:*}
		bg_name=":${bg_dirty_thresh}${unit}"
	}

	# not meaningful to run too many dd's for NFS and low memory system
	[[ $nr_dd -gt 10 && $fstype = nfs ]] && return
	[[ $nr_dd -gt 10 && $dirty_thresh -lt 100 && $unit = M ]] && return

	# in case the test box has more devices than necessary for current case
	devices=$(echo $devices | cut -f-$ndisk -d' ')
	ndisk=$(echo $devices | wc -w)

	if (( $ndisk == 1 )); then
		[[ $storage != HDD ]] && storage_prefix=$storage-
		output_dir="${storage_prefix}thresh=${dirty_thresh}${unit}${bg_name}"
	else
		output_dir="$array-${ndisk}${storage}-thresh=${dirty_thresh}${unit}${bg_name}"
		RAID_LEVEL=${array,,*}
	fi

	make_dir $output_dir $(dd_job) || return

	[[ $unit = M || $unit = m ]] && bits=20
	[[ $unit = G || $unit = g ]] && bits=30

	[[ $bg_dirty_thresh ]] && {
	echo $((bg_dirty_thresh<<bits)) > /proc/sys/vm/dirty_background_bytes
	}
	echo $((dirty_thresh<<bits)) > /proc/sys/vm/dirty_bytes

	[[ $fstype = nfs ]] && {
	echo $((dirty_thresh<<(bits - 13))) > /proc/sys/fs/nfs/nfs_congestion_kb
	}

	run_test dd
}

thresh_0()	{ thresh 0;      }
thresh_1m()	{ thresh 1    M; }
thresh_10m()	{ thresh 10   M; }
thresh_100m()	{ thresh 100  M; }
thresh_1000m()	{ thresh 1000 M; }

thresh_2g()	{ thresh 2    G; }
thresh_4g()	{ thresh 4    G; }
thresh_8g()	{ thresh 8    G; }

thresh_1g()	{ thresh 1    G; }
thresh_10g()	{ thresh 10   G; }
thresh_100g()	{ thresh 100  G; }
thresh_1000g()	{ thresh 1000 G; }

thresh_1000m_999m()	{ thresh 1000:999 M; }
thresh_1000m_990m()	{ thresh 1000:990 M; }

jbod_10hdd_thresh_1m()		{ thresh 1    M 10; }
jbod_10hdd_thresh_10m()		{ thresh 10   M 10; }
jbod_10hdd_thresh_100m()	{ thresh 100  M 10; }
jbod_10hdd_thresh_1000m()	{ thresh 1000 M 10; }

jbod_10hdd_thresh_1g()		{ thresh 1    G 10; }
jbod_10hdd_thresh_2g()		{ thresh 2    G 10; }
jbod_10hdd_thresh_4g()		{ thresh 4    G 10; }
jbod_10hdd_thresh_8g()		{ thresh 8    G 10; }
jbod_10hdd_thresh_10g()		{ thresh 10   G 10; }
jbod_10hdd_thresh_100g()	{ thresh 100  G 10; }
jbod_10hdd_thresh_1000g()	{ thresh 1000 G 10; }

jbod_2hdd_thresh_1m()		{ thresh 1    M 2; }
jbod_2hdd_thresh_10m()		{ thresh 10   M 2; }
jbod_2hdd_thresh_100m()		{ thresh 100  M 2; }
jbod_2hdd_thresh_1000m()	{ thresh 1000 M 2; }

jbod_4hdd_thresh_1m()		{ thresh 1    M 4; }
jbod_4hdd_thresh_10m()		{ thresh 10   M 4; }
jbod_4hdd_thresh_100m()		{ thresh 100  M 4; }
jbod_4hdd_thresh_1000m()	{ thresh 1000 M 4; }

jbod_4hdd_thresh_1g()		{ thresh 1    G 4; }
jbod_4hdd_thresh_2g()		{ thresh 2    G 4; }
jbod_4hdd_thresh_4g()		{ thresh 4    G 4; }
jbod_4hdd_thresh_8g()		{ thresh 8    G 4; }
jbod_4hdd_thresh_10g()		{ thresh 10   G 4; }
jbod_4hdd_thresh_100g()		{ thresh 100  G 4; }
jbod_4hdd_thresh_1000g()	{ thresh 1000 G 4; }

raid0_10hdd_thresh_1m()		{ thresh 1    M 10 RAID0; }
raid0_10hdd_thresh_10m()	{ thresh 10   M 10 RAID0; }
raid0_10hdd_thresh_100m()	{ thresh 100  M 10 RAID0; }
raid0_10hdd_thresh_1000m()	{ thresh 1000 M 10 RAID0; }

raid0_10hdd_thresh_1g()		{ thresh 1    G 10 RAID0; }
raid0_10hdd_thresh_2g()		{ thresh 2    G 10 RAID0; }
raid0_10hdd_thresh_4g()		{ thresh 4    G 10 RAID0; }
raid0_10hdd_thresh_8g()		{ thresh 8    G 10 RAID0; }
raid0_10hdd_thresh_10g()	{ thresh 10   G 10 RAID0; }
raid0_10hdd_thresh_100g()	{ thresh 100  G 10 RAID0; }
raid0_10hdd_thresh_1000g()	{ thresh 1000 G 10 RAID0; }

mem() {
	for i in $(</proc/cmdline)
	do
		[[ $i =~ "mem=" ]] && mem=$i
	done

	make_dir $mem $(dd_job) || return

	run_test dd
}

