
DEVICES="/dev/sda7"

FILESYSTEMS="xfs ext4 ext3 ext3:jsize=8 btrfs"
DD_TASKS="1 10 100"
# FILESYSTEMS="xfs"
# DD_TASKS="1 2 3"
# DD_TASKS="1"

test_cases() {
	echo
	# echo mem
	# return
	echo thresh_8g
	echo thresh_2g
	echo thresh_1000m
	echo thresh_100m
	echo thresh_10m
	echo thresh_1m
	return
	echo thresh_10g
}
