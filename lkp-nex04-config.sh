DEVICES="
$(echo /dev/disk/by-id/ata-INTEL_SSD*part1 | xargs -n1 readlink -f | sort)
"

FILESYSTEMS="ext4 xfs btrfs"
DD_TASKS="1 10 100"

KERNEL_OPTIONS=("")

KERNELS=(
3.0.0
3.1.0
3.2.0
3.3.0
)

test_cases() {
	echo

	echo jbod_12hdd_thresh_100m
	echo jbod_12hdd_thresh_1000m
	echo jbod_12hdd_thresh_8g

	echo raid0_12hdd_thresh_100m
	echo raid0_12hdd_thresh_1000m
	echo raid0_12hdd_thresh_8g

	echo raid5_12hdd_thresh_100m
	echo raid5_12hdd_thresh_1000m
	echo raid5_12hdd_thresh_8g

}

