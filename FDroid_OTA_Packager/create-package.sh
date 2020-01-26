#!/bin/bash
#

### settings
fdroid_url="https://f-droid.org/repo/org.fdroid.fdroid.privileged.ota_2110.zip"
### end of settings

set -e

self_dir="$( cd "$( dirname "$0" )" && pwd )"
scripts_dir="$self_dir/scripts"
workspace="$self_dir/workspace"

"$scripts_dir/00-cleanup.sh" "$workspace"
"$scripts_dir/01-download.sh" "$fdroid_url" "$workspace"