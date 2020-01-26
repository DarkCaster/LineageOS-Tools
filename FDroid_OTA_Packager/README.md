# Repackage FDroid privileged extension OTA zip file to be fully compatible with lineage os 16 recovery

Unfortunately, "FDroid privileged extension" OTA zip file (at least build 2110) - cannot be properly installed with lineage os 16 recovery on A\B devices (at least).

Use `create-package.sh` to download original zip file, fix installation script, and create proper OTA zip package.