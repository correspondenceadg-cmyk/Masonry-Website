#!/bin/bash
DATA_DIR="./data_collection"
ARCHIVE="data_cache.tar.zst"
CHECKSUM="checksums.sha256"
PAR2="data_cache.par2"

tar -cf - "$DATA_DIR" | zstd -22 -T0 -o "$ARCHIVE"
find "$DATA_DIR" -type f -exec sha256sum {} \; > "$CHECKSUM"
sha256sum "$ARCHIVE" >> "$CHECKSUM"
par2 create -r10 "$PAR2" "$ARCHIVE"
par2 verify "$PAR2"
echo "Archive created: $ARCHIVE"