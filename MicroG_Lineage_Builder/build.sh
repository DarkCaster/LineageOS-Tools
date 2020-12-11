#!/bin/bash

#example how to invoke sandboxer for building lineage os, and pass custom package names via cmdline

set -e

self_dir="$(cd "$(dirname "$0")" && pwd)"

chmod 700 "$self_dir/userscripts"/*

sandboxer lineageos.cfg.lua build GmsCore GsfProxy FakeStore MozillaNlpBackend NominatimNlpBackend com.google.android.maps.jar FDroid QKSMS additional_repos.xml
