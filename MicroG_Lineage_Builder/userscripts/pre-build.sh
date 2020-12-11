#!/bin/bash

# disable updater utility for custom build

sed -i 's|Updater \\|\\|g' vendor/lineage/config/common.mk
sed -i 's|Updater|\\|g' vendor/lineage/config/common.mk
