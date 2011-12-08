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
	echo ukey_thresh_100m

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

ukey_hdd() {
	make_dir UKEY-HDD $(dd_job) || return
	run_test dd
}

ukey_thresh() {
	storage=UKEY
	devices=/dev/sdb3
	thresh "$@"
}

ukey_thresh_0()		{ ukey_thresh 0;      }
ukey_thresh_1m()	{ ukey_thresh 1    M; }
ukey_thresh_10m()	{ ukey_thresh 10   M; }
ukey_thresh_100m()	{ ukey_thresh 100  M; }
ukey_thresh_1000m()	{ ukey_thresh 1000 M; }

