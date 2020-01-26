#!/bin/bash
#

### settings
fdroid_url="https://f-droid.org/repo/org.fdroid.fdroid.privileged.ota_2110.zip"
### end of settings

set -e

self_dir="$( cd "$( dirname "$0" )" && pwd )"
scripts_dir="$self_dir/scripts"

"$scripts_dir/00-cleanup.sh" "$self_dir"
"$scripts_dir/01-download.sh" "$fdroid_url" "$self_dir"
