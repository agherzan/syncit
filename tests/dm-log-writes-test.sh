#!/bin/bash

set -e

# Adjust as you want
WRITES_TOTAL_SIZE_M=(20 20 20 20)
WRITES_SIZE_M=(10 10 10 10)
WRITES_OFFSET_M=(0 3 6 9)
WRITES_SYNC=(y y y y)
WRITES_ATOMIC=(y y y y)
SYNC="sync"

# Don't touch
RESULTS_INITIAL_MD5=()
RESULTS_FINAL_MD5=()
RESULTS_CURRENT_MD5=()
RESULTS_FAILED_STATES=()
RESULTS_FAILED_FSCK=()
DEVSIZE="512M"
WORKDIR=/tmp/dm-log-test-workdir
REPLAYLOG="replay-log"
MOUNTPOINT="${WORKDIR}/mountpoint"
SNAPSHOTBASE="replay-base"
SNAPSHOTCOW="replay-cow"
FSCK="no"
FS="ext4"
SYNC_PER_FILE_AT_CREATION="y"

# Cleanup working directories
rm -rf "$WORKDIR"
mkdir -p "$WORKDIR/mountpoint"


writefile() {
	local _bkpext="bkp"
	local _idx=$1
	local _size=$2
	local _seek=$3
	local _sync=$4
	local _atomic=$5
	if [ "$_atomic" == "y" ]; then
		dd if=/dev/urandom of=$MOUNTPOINT/pattern${_idx}.${_bkpext} bs=1M count=${_size} seek=${_seek} conv=notrunc
		$SYNC $MOUNTPOINT/pattern${_idx}.${_bkpext}
		mv $MOUNTPOINT/pattern${_idx}.${_bkpext} $MOUNTPOINT/pattern${_idx}
	else
		dd if=/dev/urandom of=$MOUNTPOINT/pattern${_idx} bs=1M count=${_size} seek=${_seek} conv=notrunc
	fi
	if [ "$_sync" == "y" ]; then
		$SYNC $MOUNTPOINT/pattern$_idx
	fi
}

try() {
	local _max=$1
	shift
	local _command="$@ 2>&1"
	local _try=0
	local _timeout=0.1
	local _output
	set +e
	until [ $_try -ge $_max ]; do
		_output=$(eval $_command) && break
		_try=$(($_try+1))
		sleep $_timeout
	done
	if [ $_try -ge $_max ]; then
		echo "\"$@\" failed after $_max attempts with output:"
		echo "$_output"
		exit 1
	fi
	set -e
}

help() {
	cat << EOF
	$0 <OPTION>

	Options:
		-f, --fsck
			Run filesystem check before and after md5 check when replaying fs
			states.
		--sync-util
			Sync binary to use.
			Default: sync.
		--filesystem
			Filesystem to use.
			Default: ext4.
		--no-sync-per-file-at-creation
			Do not sync each file upon creation (before logging).
			It will only sync the entire system after all initial files are
			created and before starting to log.
		--limit-patterns
			By default the script will run all the patterns defined by the set
			of variable WRITES_*. You can limit to run only the first n patterns
			by setting this argument.
EOF
}

# Parse auguments
while [[ $# > 0 ]]; do
	arg="$1"
	case $arg in
		-h|--help)
			help
			exit 0
			;;
		-f|--fsck)
			FSCK="yes"
			;;
		--sync-util)
			if [ -z "$2" ]; then
				log ERROR "\"$1\" argument needs a value."
			fi
			SYNC=$2
			shift
			;;
		--filesystem)
			if [ -z "$2" ]; then
				log ERROR "\"$1\" argument needs a value."
			fi
			FS=$2
			shift
			;;
		--no-sync-per-file-at-creation)
			SYNC_PER_FILE_AT_CREATION="n"
			;;
		--limit-patterns)
			if [ -z "$2" ]; then
				log ERROR "\"$1\" argument needs a value."
			fi
			PATTERNS=$2
			shift
			;;
		*)
			echo "Unrecognized option $1."
			help
			exit 1
			;;
	esac
	shift
done

# Handle limit number of patterns
if [ -z "$PATTERNS" ] || [ $PATTERNS -ge ${#WRITES_TOTAL_SIZE_M[@]} ]; then
	PATTERNS=${!WRITES_TOTAL_SIZE_M[@]}
else
	PATTERNS="$(seq 0 $((PATTERNS-1)))"
fi

cleanup () {
	EXIT_CODE=$?
	echo "Cleanup..."
	$SYNC ; sleep 1
	dmsetup remove log > /dev/null 2>&1 || true
	dmsetup remove $SNAPSHOTCOW > /dev/null 2>&1 || true
	dmsetup remove $SNAPSHOTBASE > /dev/null 2>&1 || true
	losetup -d "$DEV" "$LOGDEV" "$COW_LOOP_DEV" > /dev/null 2>&1 || true
	umount "$MOUNTPOINT" > /dev/null 2>&1 || true
	exit $EXIT_CODE
}
trap cleanup EXIT SIGHUP SIGINT SIGTERM

# Setup loop devices
dd if=/dev/zero of="$WORKDIR/dev" bs=1 count=0 seek="$DEVSIZE"
dd if=/dev/zero of="$WORKDIR/logdev" bs=1 count=0 seek="$DEVSIZE"
DEV=$(losetup -f --show "$WORKDIR/dev")
LOGDEV=$(losetup -f --show "$WORKDIR/logdev")

# Create dm with initial files
DEV_SIZE=$(blockdev --getsz "$DEV")
TABLE="0 $DEV_SIZE log-writes $DEV $LOGDEV"
dmsetup create log --table "$TABLE"
echo "Creating $FS filesystem"...
$SYNC
mkfs.$FS /dev/mapper/log
mount /dev/mapper/log "$MOUNTPOINT"
for i in $PATTERNS; do
	writefile "$i" "${WRITES_TOTAL_SIZE_M[$i]}" "0" "$SYNC_PER_FILE_AT_CREATION" "n"
	$SYNC $MOUNTPOINT
	RESULTS_INITIAL_MD5[$i]=$(md5sum "$MOUNTPOINT/pattern$i" | awk '{print $1}')
done
umount $MOUNTPOINT ; $SYNC

# Log writes
mount /dev/mapper/log "$MOUNTPOINT"
dmsetup message log 0 mark write
for i in $PATTERNS; do
	writefile "$i" "${WRITES_SIZE_M[$i]}" "${WRITES_OFFSET_M[$i]}" "${WRITES_SYNC[$i]}" "${WRITES_ATOMIC[$i]}"
done
dmsetup message log 0 mark written
$SYNC

# Save final md5s
for i in $PATTERNS; do
	RESULTS_FINAL_MD5[$i]=$(md5sum "$MOUNTPOINT/pattern$i" | awk '{print $1}')
	echo "Pattern $i from ${RESULTS_INITIAL_MD5[$i]} to ${RESULTS_FINAL_MD5[$i]}."
done

umount "$MOUNTPOINT"
dmsetup remove log

echo "Setting snapshot base..."
ORIGIN_TABLE="0 $DEV_SIZE snapshot-origin $DEV"

# Create a sparse file
echo "Setting up COW TABLE..."
rm -rf ${WORKDIR}/cow-dev
dd if=/dev/zero of=${WORKDIR}/cow-dev bs=1 count=0 seek=50M
COW_LOOP_DEV=$(losetup -f --show ${WORKDIR}/cow-dev)
COW_TABLE="0 $DEV_SIZE snapshot /dev/mapper/$SNAPSHOTBASE $COW_LOOP_DEV N 8"
TARGET=/dev/mapper/$SNAPSHOTCOW

echo "replaying to mark"
# Initilize failed for nice output
for i in $PATTERNS; do
	RESULTS_FAILED_FSCK[$i]=0
	RESULTS_FAILED_STATES[$i]=0
done
ENTRY=$($REPLAYLOG --log $LOGDEV --find --end-mark write)
LAST_ENTRY=$($REPLAYLOG --log $LOGDEV --find --end-mark written)
STATES=$((LAST_ENTRY-ENTRY-1))
$REPLAYLOG --log $LOGDEV --replay $DEV --limit $ENTRY
let ENTRY+=1
while [ $ENTRY -lt $LAST_ENTRY ]; do
	$REPLAYLOG --limit 1 --log $LOGDEV --replay $DEV --start $ENTRY
	try 3 dmsetup create $SNAPSHOTBASE --table "\"$ORIGIN_TABLE\""
	try 3 dmsetup create $SNAPSHOTCOW --table "\"$COW_TABLE\""
	# Give a little time for dm to settle otherwise the device might not exist.
	# It doesn't try multiple times because running the first time might fix the fs
	# making the second time pass fine which makes us not spotting the problem.
	if [ "$FSCK" == "yes" ]; then
		sleep 0.1
		set +e
		fsck -y $TARGET
		if [ $? -ne 0 ]; then
			let RESULTS_FAILED_FSCK[$i]+=1
		fi
		set -e
	fi
	try 3 mount $TARGET $MOUNTPOINT
	for i in $PATTERNS; do
		RESULTS_CURRENT_MD5[$i]=$(md5sum $MOUNTPOINT/pattern$i | awk '{print $1}')
		if [ "${RESULTS_CURRENT_MD5[$i]}" = "${RESULTS_INITIAL_MD5[$i]}" -o "${RESULTS_CURRENT_MD5[$i]}" = "${RESULTS_FINAL_MD5[$i]}" ]; then
			RESULT="pass"
		else
			RESULT="failed"
			let RESULTS_FAILED_STATES[$i]+=1
		fi
		echo "[$ENTRY/$LAST_ENTRY] Pattern$i current=${RESULTS_CURRENT_MD5[$i]} [${RESULTS_INITIAL_MD5[$i]} -> ${RESULTS_FINAL_MD5[$i]}] [$RESULT]"
	done
	umount $MOUNTPOINT
	$SYNC
	dmsetup remove $SNAPSHOTCOW
	dmsetup remove $SNAPSHOTBASE
	let ENTRY+=1
done

# Report
echo -e "\nFilesystem $FS:"
for i in $PATTERNS; do
	echo -e "Pattern$i (sync=${WRITES_SYNC[$i]}) md5sum check failed in ${RESULTS_FAILED_STATES[$i]} states and ${RESULTS_FAILED_FSCK[$i]} fs checks out of $STATES replayed states. Did$(if [ ${RESULTS_CURRENT_MD5[$i]} != ${RESULTS_FINAL_MD5[$i]} ]; then echo " not"; fi) arrive at final md5.\n"
done
