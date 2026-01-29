#!/usr/bin/env bash

SCRIPTDIR="$(readlink -f $0)"
SCRIPTDIR="$(dirname "${SCRIPTDIR}")"

PSXDIR=$SCRIPTDIR/ps1_assets

DSTREAM=$SCRIPTDIR/dstream.bin
DBANK=$SCRIPTDIR/dbank.bin
VAG2WAV=$SCRIPTDIR/vag2wav.bin


TEMPDIR=$(mktemp -d)
trap "rm -rf $TEMPDIR" EXIT

cd $TEMPDIR

for DIR in $PSXDIR/*.DIR; do
    TMP=$(basename $DIR)
    mkdir -p $TMP

    (cd $TMP; $DSTREAM $DIR ${DIR::-4}.bin > /dev/null)

    for VAG in $TMP/*.VAG; do
	$VAG2WAV $VAG ${VAG::-4}.WAV > /dev/null
    done

#    for BOF in $TEMPDIR/$TMP/*.BOF; do
#	(cd $TMP; $DBANK $BOF ${BOF::-4}.BNK > /dev/null)
#    done
done

for STREAM in STREAM*; do
    mkdir -p $STREAM/mpq
    while read -r SRC DST; do
	mkdir -p $(dirname $STREAM/mpq/$DST)
	cp $STREAM/$SRC $STREAM/mpq/$DST
    done < $SCRIPTDIR/${STREAM::-4}.map

    MPQ=$SCRIPTDIR/${STREAM::-4}.mpq
    rm -rf $MPQ
    smpq -M 1 -C none -c $MPQ
    (cd $STREAM/mpq; find * -type f -exec smpq -a -C none $MPQ "{}" \;)
done
