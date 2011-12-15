DEVICES="/dev/sda7"
DEVICES="/dev/sdb1 /dev/sdc1 /dev/sdd1 /dev/sde1"

FILESYSTEMS="nfs"
FILESYSTEMS="xfs ext4 ext3 btrfs"
DD_TASKS="1 10 100"
# FILESYSTEMS="xfs"
# DD_TASKS="1 2 3"
# DD_TASKS="1"

test_cases() {
	echo

	echo jbod_4hdd_thresh_8g
	echo jbod_4hdd_thresh_1g
	echo jbod_4hdd_thresh_100m

	return

	echo thresh_8g
	echo thresh_2g
	echo thresh_1000m
	echo thresh_100m
	echo thresh_10m
	echo thresh_1m

	return
	echo thresh_10g
}
