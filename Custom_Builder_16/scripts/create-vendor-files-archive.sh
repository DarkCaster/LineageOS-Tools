#!/bin/bash
#

set -e

show_usage() {
  echo "usage: archive-vendor-files.sh <lineage os source dir> <vendor> <archive>"
  exit 1
}

lineage_scrdir="$1"
[[ -z $lineage_scrdir ]] && show_usage

vendor="$2"
[[ -z $vendor ]] && show_usage

target_file="$3"
[[ -z $target_file ]] && show_usage
target_file=$(readlink -f "$target_file")

self_dir="$( cd "$( dirname "$0" )" && pwd )"

rm -fv "$target_file"

echo "Creating archive with vendor files for vendor: $vendor"
"$self_dir/create-archive.sh" "$lineage_scrdir/vendor/$vendor" "$target_file"
