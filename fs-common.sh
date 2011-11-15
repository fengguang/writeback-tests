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
		;;
	ext*)
		[[ $fs =~ :wb ]] && mntopt="-o data=writeback"
		[[ $fs =~ :jsize=8 ]] && mkfsopt="-J size=8"
		;;
	nfs)
		mntopt="-o v3,nolock"
		bdevs=$NFS_DEVICE
		;;
	esac
}

destroy_devices() {
	for dev in $devices
	do
		dd if=/dev/zero of=$dev bs=4k count=100
	done
}

make_md() {
	[[ $fstype = 'nfs' ]] && return

	[[ $RAID_LEVEL =~ raid ]] || {
		bdevs="$devices"
		return
	}

	[[ $fstype = 'btrfs' ]] && {
		bdevs=$(echo $devices | cut -f1 -d' ')
		return
	}

	bdevs=/dev/md0
	mdadm --stop $bdevs
	mdadm --create $bdevs --chunk=${RAID_CHUNK:-1024} --level=$RAID_LEVEL --raid-devices=$nr_devices --force --assume-clean $devices
	echo 1280 > /sys/block/md0/queue/nr_requests
}

make_fs() {
	[[ $fstype = 'nfs' ]] && return

	[[ $fstype = 'btrfs' && $RAID_LEVEL =~ raid ]] && {
		mkfs -t $fstype $mkfsopt $devices
		return
	}

	for dev in $bdevs
	do
		echo mkfs -t $fstype $mkfsopt $dev
		mkfs -t $fstype $mkfsopt $dev &
	done
	wait
}

mount_fs() {
	for dev in $bdevs
	do
		mnt=$MNT/$(basename $dev)
		mkdir -p $mnt
		echo mount -t $fstype $mntopt $dev $mnt
		mount -t $fstype $mntopt $dev $mnt
	done
}
