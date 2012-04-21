#
# the global defaults can be overrode by individual host configs
#

#
# kill dd and finish test after so many seconds
#
RUNTIME=600

#
# mount target test partitions under $MNT/<device name>/
#
MNT=/fs

#
# for nfs tests
#
NFS_DEVICE=bay:/nfs
NFS_DEVICE=192.168.1.91:/nfs

#
# block size for dd
#
bs=64k

#
# repeat each test so many times
#
LOOPS=2

#
# It takes time to parse and plot the trace events. I would disable this and
# run a dedicated plot-traces.sh in the NFS server.
#
PLOT_IN_TESTBOX=1

#
# this is convenient for me to manage files in the NFS server
#
umask 002
