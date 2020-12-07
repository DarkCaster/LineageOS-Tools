-- config file for sandboxer isolation suite container: https://github.com/DarkCaster/Sandboxer

defaults.recalculate_orig=defaults.recalculate

function defaults.recalculate()
  tunables.features.x11host_target_dir="/dev/null"
  tunables.datadir=loader.path.combine(loader.workdir,"userdata-lineage-dev")
  defaults.recalculate_orig()
  defaults.mounts.resolvconf_mount=defaults.mounts.direct_resolvconf_mount
  defaults.mounts.hosts_mount=defaults.mounts.direct_hosts_mount
  defaults.mounts.hostname_mount=defaults.mounts.direct_hostname_mount
end

defaults.recalculate()

-- load base config
dofile(loader.path.combine(loader.workdir,"debian-sandbox.cfg.lua"))

-- remove some unneded features and mounts
loader.table.remove_value(sandbox.features,"dbus")
loader.table.remove_value(sandbox.features,"gvfs_fix")
loader.table.remove_value(sandbox.features,"pulse")
loader.table.remove_value(sandbox.features,"x11host")

-- remove some mounts from base config
loader.table.remove_value(sandbox.setup.mounts,defaults.mounts.devsnd_mount)
loader.table.remove_value(sandbox.setup.mounts,defaults.mounts.devdri_mount)
loader.table.remove_value(sandbox.setup.mounts,defaults.mounts.devinput_mount)
loader.table.remove_value(sandbox.setup.mounts,defaults.mounts.devshm_mount)


-- /sys mount is needed for adb\fastboot to work, uncomment next line to disable it
-- loader.table.remove_value(sandbox.setup.mounts,defaults.mounts.sys_mount)

table.insert(sandbox.setup.mounts,{prio=98,"dev-bind","/dev/bus/usb","/dev/bus/usb"})

-- set hostname to "sandbox"
table.insert(sandbox.bwrap,defaults.bwrap.hostname_sandbox)

-- add bwrap unshare_ipc option
loader.table.remove_value(sandbox.bwrap,defaults.bwrap.unshare_ipc)
table.insert(sandbox.bwrap,defaults.bwrap.unshare_ipc)
loader.table.remove_value(sandbox.bwrap,defaults.bwrap.unshare_cgroup)

-- add mounts with sources directory
_MIRROR_DIR="/srv/mirror"
_SRC_DIR="/srv/src"
_TMP_DIR="/srv/tmp"
_CCACHE_DIR="/srv/ccache"
_ZIP_DIR="/srv/zips"
_LMANIFEST_DIR="/srv/local_manifests"
_KEYS_DIR="/srv/keys"
_LOGS_DIR="/srv/logs"
_USERSCRIPTS_DIR="/srv/userscripts"

table.insert(sandbox.setup.commands,{'mkdir -p "'..loader.workdir..'/build/mirror"'});
table.insert(sandbox.setup.commands,{'mkdir -p "'..loader.workdir..'/build/src"'});
table.insert(sandbox.setup.commands,{'mkdir -p "'..loader.workdir..'/build/tmp"'});
table.insert(sandbox.setup.commands,{'mkdir -p "'..loader.workdir..'/build/ccache"'});
table.insert(sandbox.setup.commands,{'mkdir -p "'..loader.workdir..'/build/zips"'});
table.insert(sandbox.setup.commands,{'mkdir -p "'..loader.workdir..'/build/local_manifests"'});
table.insert(sandbox.setup.commands,{'mkdir -p "'..loader.workdir..'/build/keys"'});
table.insert(sandbox.setup.commands,{'mkdir -p "'..loader.workdir..'/build/logs"'});
table.insert(sandbox.setup.commands,{'mkdir -p "'..loader.workdir..'/build/userscripts"'});

table.insert(sandbox.setup.mounts,{prio=99,tag="_SRV_DIR","tmpfs","/srv"})
table.insert(sandbox.setup.mounts,{prio=100,tag="_MIRROR_DIR","bind",loader.path.combine(loader.workdir,"build","mirror"),_MIRROR_DIR})
table.insert(sandbox.setup.mounts,{prio=100,tag="_SRC_DIR","bind",loader.path.combine(loader.workdir,"build","src"),_SRC_DIR})
table.insert(sandbox.setup.mounts,{prio=100,tag="_TMP_DIR","bind",loader.path.combine(loader.workdir,"build","tmp"),_TMP_DIR})
table.insert(sandbox.setup.mounts,{prio=100,tag="_CCACHE_DIR","bind",loader.path.combine(loader.workdir,"build","ccache"),_CCACHE_DIR})
table.insert(sandbox.setup.mounts,{prio=100,tag="_ZIP_DIR","bind",loader.path.combine(loader.workdir,"build","zips"),_ZIP_DIR})
table.insert(sandbox.setup.mounts,{prio=100,tag="_LMANIFEST_DIR","bind",loader.path.combine(loader.workdir,"build","local_manifests"),_LMANIFEST_DIR})
table.insert(sandbox.setup.mounts,{prio=100,tag="_KEYS_DIR","bind",loader.path.combine(loader.workdir,"build","keys"),_KEYS_DIR})
table.insert(sandbox.setup.mounts,{prio=100,tag="_LOGS_DIR","bind",loader.path.combine(loader.workdir,"build","logs"),_LOGS_DIR})
table.insert(sandbox.setup.mounts,{prio=100,tag="_USERSCRIPTS_DIR","bind",loader.path.combine(loader.workdir,"build","userscripts"),_USERSCRIPTS_DIR})

-- just comment-out this whole block if sandbox not working because some of required utilities missing
-- currently, this params should work only with my setup
sandbox.bwrap_cmd={
  --"netns-runner.sh", "vde_air",
  "ionice","-c","3",
  "nice","-n","19",
  "taskset","--cpu-list","3,4,5,6,7,8,9,10,11,15,16,17,18,19,20,21,22,23",
  "bwrap"
}

shell.term_orphans=true
shell.env_unset={"TERM","LANG","MAIL"}

-- define some variables, needed for build scripts
shell.env_set={
  {"TERM","xterm"},
  {"LANG","en_US.UTF-8"},

  {"MIRROR_DIR",_MIRROR_DIR},
  {"SRC_DIR",_SRC_DIR},
  {"TMP_DIR",_TMP_DIR},
  {"CCACHE_DIR",_CCACHE_DIR},
  {"ZIP_DIR",_ZIP_DIR},
  {"LMANIFEST_DIR",_LMANIFEST_DIR},
  {"KEYS_DIR",_KEYS_DIR},
  {"LOGS_DIR",_LOGS_DIR},
  {"USERSCRIPTS_DIR",_USERSCRIPTS_DIR},

  -- config options
  {"USE_CCACHE","1"},
  {"CCACHE_SIZE","50G"},
  {"CCACHE_EXEC","/usr/bin/ccache"},
  {"BRANCH_NAME","lineage-17.1"},
  {"DEVICE_LIST","river"}, --moto g7
  {"RELEASE_TYPE","CUSTOM"},
  {"OTA_URL",""},
  {"USER_NAME","LineageOS Buildbot"},
  {"USER_MAIL","sandbox@sandboxer.host"},
  {"INCLUDE_PROPRIETARY","true"},
  {"BUILD_OVERLAY","false"},
  {"LOCAL_MIRROR","false"},
  {"CLEAN_OUTDIR","false"},
  {"CRONTAB_TIME","now"},
  {"CLEAN_AFTER_BUILD","true"},
  {"WITH_SU","false"},
  {"ANDROID_JACK_VM_ARGS","-Dfile.encoding=UTF-8 -XX:+TieredCompilation -Xmx4G"},
  {"CUSTOM_PACKAGES",""},
  {"SIGN_BUILDS","true"},
  {"KEYS_SUBJECT","/C=US/ST=California/L=Mountain View/O=Android/OU=Android/CN=Android/emailAddress=android@android.com"},
  {"ZIP_SUBDIR","true"},
  {"LOGS_SUBDIR","true"},
  {"SIGNATURE_SPOOFING","restricted"},
  {"DELETE_OLD_ZIPS","0"},
  {"DELETE_OLD_LOGS","0"},
}
