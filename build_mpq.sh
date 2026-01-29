#!/usr/bin/env bash
#
# Build MPQ files from PlayStation (PSX) Diablo assets.
#
# Required external executables:
#   - dstream.bin: extract PSX .DIR/.BIN archives
#   - dbank.bin  : convert .BOF sound banks to .BNK
#   - vag2wav.bin: convert PSX VAG audio to WAV
#   - smpq       : create and populate MPQ archives
#

# Resolve the absolute path of this script
SCRIPTDIR="$(readlink -f "$0")"
SCRIPTDIR="$(dirname "${SCRIPTDIR}")"

# Directory containing original PSX asset files
PSXDIR="$SCRIPTDIR/ps1_assets"

# Helper tools used for extracting and converting assets
DSTREAM="$SCRIPTDIR/dstream.bin"
DBANK="$SCRIPTDIR/dbank.bin"
VAG2WAV="$SCRIPTDIR/vag2wav.bin"

# Create a temporary working directory and ensure cleanup on exit
TEMPDIR="$(mktemp -d)"
trap 'rm -rf "$TEMPDIR"' EXIT

cd "$TEMPDIR"

# Process each PSX .DIR archive
for DIR in "$PSXDIR"/*.DIR; do
    TMP="$(basename "$DIR")"
    mkdir -p "$TMP"

    (cd "$TMP"; "$DSTREAM" "$DIR" "${DIR%.DIR}.BIN" > /dev/null)

    # Convert extracted VAG audio files to WAV
    for VAG in $TMP/*.VAG; do
	"$VAG2WAV" "$VAG" "${VAG%.VAG}.WAV" > /dev/null
    done

    # (Optional) Convert BOF sound banks to BNK format
    # for BOF in "$TEMPDIR/$TMP"/*.BOF; do
	# (cd "$TMP"; "$DBANK" "$BOF" "${BOF%.BOF}.BNK" > /dev/null)
    # done
done

# Build MPQ files using mapping definitions
for STREAM in STREAM?.DIR; do
    # Convert directory name to lowercase and remove .DIR suffix (bash 3.2 compatible)
    STREAM_BASE="${STREAM%.DIR}"
    STREAM_LOWER=$(echo "$STREAM_BASE" | tr '[:upper:]' '[:lower:]')

    mkdir -p "$STREAM/mpq"
    while read -r SRC DST; do
	mkdir -p "$(dirname "$STREAM/mpq/$DST")"
	cp "$STREAM/$SRC" "$STREAM/mpq/$DST"
    done < "$SCRIPTDIR/$STREAM_LOWER.map"

    MPQ="$SCRIPTDIR/$STREAM_LOWER.mpq"
    rm -rf "$MPQ"
    smpq -M 1 -C none -c "$MPQ"
    (cd "$STREAM/mpq"; find * -type f -exec smpq -a -C none "$MPQ" "{}" \;)
done
