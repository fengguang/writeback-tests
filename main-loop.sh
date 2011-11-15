#!/bin/bash
#
# main-loop.sh: repeat tests under various combinations of fs/dd

cd $(dirname $0)

BASE_DIR=$(pwd)

# in my case, it's running from rc.local
export PATH=$BASE_DIR:/root/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

source config.sh
source $(hostname)-config.sh || exit

source fs-common.sh
source dd-common.sh
source trace-common.sh
source cases-common.sh

for loop in $(seq ${LOOPS:-1})
do
for nr_dd in ${DD_TASKS:-1}
do
for fs in ${FILESYSTEMS:-ext4}
do
for scheme in $(test_cases)
do
	devices=$DEVICES
	if [[ $scheme =~ ^fio_ && -f $scheme ]]; then
		fio_job $scheme
	else
		$scheme
	fi
done
done
done
done

# when all done, boot & test next kernel
wget -q "http://bee/~wfg/cgi-bin/gpxelinux.cgi?hostname=$(hostname)&test_all_done" -O- | head -1 | grep -q reboot && reboot &
