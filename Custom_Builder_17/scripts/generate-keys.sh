#!/bin/bash
#

set -e

show_usage() {
  echo "usage: generate-keys.sh <lineage os source dir> <archive>"
  exit 1
}

lineage_srcdir="$1"
[[ -z $lineage_srcdir ]] && show_usage

target_file="$2"
[[ -z $target_file ]] && show_usage
target_file=$(readlink -f "$target_file")

self_dir="$( cd "$( dirname "$0" )" && pwd )"

rm -fv "$target_file"

tmp_dir="$TMPDIR"
[[ -z $tmp_dir || ! -d $tmp_dir ]] && tmp_dir="/tmp"
tmp_dir=$(mktemp -d --tmpdir="$tmp_dir" keys.XXXXXXXXX)

key_dir="$tmp_dir/keys"
mkdir -p "$key_dir"

pushd 1>/dev/null "$lineage_srcdir"
subject='/C=US/ST=California/L=Mountain View/O=Android/OU=Android/CN=Android/emailAddress=android@android.com'
echo "Creating signing keys..."
for key in releasekey platform shared media testkey; do
  ./development/tools/make_key "$key_dir/$key" "$subject" || true
  [[ ! -f "$key_dir/$key.pk8" || ! -f "$key_dir/$key.x509.pem" ]] && echo "failed to create key: $key" && exit 1
done
popd 1>/dev/null

echo "Creating keys archive..."
"$self_dir/create-archive.sh" "$key_dir" "$target_file"

rm -rf "$tmp_dir"
