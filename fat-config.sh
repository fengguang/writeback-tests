LOOPS=3

DEVICES="/dev/sda7 /dev/sdb3"
bs=4k

DD_TASKS="1 2 10 100"

FILESYSTEMS="xfs"
FILESYSTEMS="btrfs"
FILESYSTEMS="ext4"
FILESYSTEMS="ext3"
FILESYSTEMS="xfs ext4 ext3 btrfs"
# DD_TASKS="1"
DD_TASKS="1 10 100"

test_cases() {
	echo
	echo ukey_hdd
	echo thresh_1000m_999m
	echo thresh_1000m_990m
	echo thresh_1000m
	echo thresh_100m
	echo thresh_10m
	echo thresh_1m
	echo fio_fat_mmap_randwrite_4k
	echo fio_fat_mmap_randwrite_64k
	echo fio_fat_rates
	return

	# echo fat-fio-mmap.sh
	# echo fat-fio-rates.sh
}
