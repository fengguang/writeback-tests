
DEVICES="
/dev/sdc1
/dev/sdd1
/dev/sde1
/dev/sdf1
/dev/sdg1
/dev/sdh1
/dev/sdi1
/dev/sdj1
/dev/sdk1
/dev/sdl1
"

FILESYSTEMS="ext3 ext4 xfs btrfs"
DD_TASKS="1 10 100"

# FILESYSTEMS="ext4"
# FILESYSTEMS="xfs ext4 ext3 btrfs"
# DD_TASKS="1 100"

test_cases() {
	echo

	echo jbod_12hdd_randrw_4k
	echo jbod_12hdd_randrw_64k
	echo jbod_12hdd_randwrite_4k
	echo jbod_12hdd_randwrite_64k
	echo jbod_12hdd_mmap_randrw_4k
	echo jbod_12hdd_mmap_randrw_64k
	echo jbod_12hdd_mmap_randwrite_4k
	echo jbod_12hdd_mmap_randwrite_64k
	echo jbod_12hdd_fallocate_randwrite_4k
	echo jbod_12hdd_fallocate_randwrite_64k
	echo jbod_12hdd_fallocate_mmap_randrw_4k
	echo jbod_12hdd_fallocate_mmap_randrw_64k

	echo jbod_10hdd_thresh_100m
	echo jbod_10hdd_thresh_1000m
	echo jbod_10hdd_thresh_2g
	echo jbod_10hdd_thresh_4g

	echo jbod_4hdd_thresh_1000m
	echo jbod_4hdd_thresh_100m

	echo jbod_2hdd_thresh_100m
	echo jbod_2hdd_thresh_10m

	echo raid0_10hdd_thresh_100m
	echo raid0_10hdd_thresh_1000m
	echo raid0_10hdd_thresh_2g
	echo raid0_10hdd_thresh_4g
}
