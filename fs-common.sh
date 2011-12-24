#!/bin/bash

fs_options() {

	fstype=${fs%%:*}
	nr_devices=$(echo $devices | wc -w)

	case $fs in
	xfs)
		mntopt="-o allocsize=1g,nobarrier,inode64,delaylog"
		[[ $RAID_LEVEL =~ raid ]] && {
			mntopt+=",logbsize=262144"
			mkfsopt="-f -l size=131072b -d agcount=$nr_devices"
		}
		fs_events='xfs:*,workqueue:*'
		;;
	ext*)
		[[ $fs =~ :wb ]] && mntopt="-o data=writeback"
		[[ $fs =~ :jsize=8 ]] && mkfsopt="-J size=8"

		[[ $fstype = ext3 ]] && fs_events='ext3:*,jbd:*'
		[[ $fstype = ext4 ]] && fs_events='ext4:*,jbd2:*'
		;;
	btrfs)
		fs_events='btrfs:*'
		;;
	nfs)
		mntopt="-o v3,nolock"
		bdevs=$NFS_DEVICE
		;;
	esac
}

is_btrfs_raid_levels() {
	[[ $fstype = 'btrfs' && $RAID_LEVEL =~ raid(0|1|10) ]]
}

destroy_devices() {
	for dev in $devices
	do
		dd if=/dev/zero of=$dev bs=4k count=100

		[[ $kopt = deadline || $kopt = noop ]] && {
			disk=$(echo $dev | cut -f3 -d/ | tr -d [0-9])
			echo $kopt > /sys/block/$disk/queue/scheduler
		}
	done
}

make_md() {
	[[ $fstype = 'nfs' ]] && return

	[[ $RAID_LEVEL =~ raid ]] || {
		bdevs="$devices"
		return
	}

	is_btrfs_raid_levels && {
		bdevs=$(echo $devices | cut -f1 -d' ')
		return
	}

	bdevs=/dev/md0
	mdadm --stop $bdevs
	echo y | mdadm --create $bdevs --chunk=${RAID_CHUNK:-1024} --level=$RAID_LEVEL --raid-devices=$nr_devices --force --assume-clean $devices
}

make_fs() {
	[[ $fstype = 'nfs' ]] && return

	is_btrfs_raid_levels && {
		mkfs.btrfs --data $RAID_LEVEL $mkfsopt $devices
		return
	}

	for dev in $bdevs
	do
		echo mkfs -t $fstype $mkfsopt $dev
		mkfs -t $fstype $mkfsopt $dev &
	done
	wait || exit
}

mount_fs() {
	for dev in $bdevs
	do
		mnt=$MNT/$(basename $dev)
		mkdir -p $mnt
		echo mount -t $fstype $mntopt $dev $mnt
		mount -t $fstype $mntopt $dev $mnt || exit
	done
}
