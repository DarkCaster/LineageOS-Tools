#!/bin/bash

#example how to invoke sandboxer for building lineage os, and pass custom package names via cmdline

sandboxer lineageos.cfg.lua build GmsCore GsfProxy FakeStore MozillaNlpBackend NominatimNlpBackend com.google.android.maps.jar FDroid QKSMS DAVx5 OpenTasks additional_repos.xml
