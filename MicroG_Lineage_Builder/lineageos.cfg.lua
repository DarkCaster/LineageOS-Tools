-- config file for sandboxer isolation suite container: https://github.com/DarkCaster/Sandboxer

defaults.recalculate_orig=defaults.recalculate

function defaults.recalculate()
  tunables.features.x11host_target_dir="/dev/null"
  tunables.datadir=loader.path.combine(tunables.configdir,"userdata")
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

-- usb devfs mount needed for adb\fastboot to work
table.insert(sandbox.setup.mounts,{prio=98,"dev-bind","/dev/bus/usb","/dev/bus/usb"})

-- set hostname to "sandbox"
table.insert(sandbox.bwrap,defaults.bwrap.hostname_sandbox)

-- add bwrap unshare_ipc option
loader.table.remove_value(sandbox.bwrap,defaults.bwrap.unshare_ipc)
table.insert(sandbox.bwrap,defaults.bwrap.unshare_ipc)

-- disable creating new cgroup namespace for sandbox (TODO: remember, why exactly I need this)
loader.table.remove_value(sandbox.bwrap,defaults.bwrap.unshare_cgroup)

-- define mounts needed for CI scripts to work
_MIRROR_DIR="/srv/mirror"
_SRC_DIR="/srv/src"
_TMP_DIR="/srv/tmp"
_CCACHE_DIR="/srv/ccache"
_ZIP_DIR="/srv/zips"
_LMANIFEST_DIR="/srv/local_manifests"
_KEYS_DIR="/srv/keys"
_LOGS_DIR="/srv/logs"
_USERSCRIPTS_DIR="/srv/userscripts"

-- local git repositories
_LSOURCES_DIR="/srv/local_sources"

-- create directories for that mounts at host-side
table.insert(sandbox.setup.commands,{'\
  for d in mirror src tmp ccache logs; do \
    if [[ ! -e  "'..loader.workdir..'/build/$d" ]]; then \
      log "creating directory build/$d"; \
      mkdir -p "'..loader.workdir..'/build/$d"; \
    fi; \
  done; \
  for d in out keys local_manifests local_sources userscripts; do \
    if [[ ! -e  "'..loader.workdir..'/$d" ]]; then \
      log "creating directory $d"; \
      mkdir -p "'..loader.workdir..'/$d"; \
    fi; \
  done; \
'});

-- prepare build scripts
table.insert(sandbox.setup.commands,{
  'rm -rf "${cfg[tunables.configdir]}/builder"',
  'mkdir -p "${cfg[tunables.configdir]}/builder"',
  'cp -R "'..loader.workdir..'/CI_Scripts/src"/* "${cfg[tunables.configdir]}/builder"',
  -- allow init.sh to run scripts by sandboxer user
  'sed -i "s|-user root|-user sandboxer|g" "${cfg[tunables.configdir]}/builder/init.sh"',
  -- disable most of the logging (TODO: sandboxer logging feature may be used instead
  'sed -i "s|\\s\\?&>>\\s\\?\\"\\$repo_log\\"||g" "${cfg[tunables.configdir]}/builder/build.sh"',
  'sed -i "s|\\s\\?&>>\\s\\?\\"\\$DEBUG_LOG\\"||g" "${cfg[tunables.configdir]}/builder/build.sh"',
  'sed -i "s|\\s\\?>>\\s\\?\\"\\$DEBUG_LOG\\"||g" "${cfg[tunables.configdir]}/builder/build.sh"',
});
table.insert(sandbox.setup.mounts,{prio=100,tag="_BUILDER","bind",loader.path.combine(tunables.configdir,"builder"),"/root"})

-- save repo utility to home directory
table.insert(sandbox.setup.commands,{
  'mkdir -p "${cfg[tunables.auto.user_path]}/bin"',
  'if [[ ! -f '..loader.workdir..'/build/repo ]]; then log "downloading repo utility"; wget -q -O "'..loader.workdir..'/build/repo" "https://storage.googleapis.com/git-repo-downloads/repo"; else true; fi',
  'cp "'..loader.workdir..'/build/repo" "${cfg[tunables.auto.user_path]}/bin/repo"',
  'chmod a+x "${cfg[tunables.auto.user_path]}/bin/repo"',
});

-- add mounts for CI sctipts to work
table.insert(sandbox.setup.mounts,{prio=99,tag="_SRV_DIR","tmpfs","/srv"})
table.insert(sandbox.setup.mounts,{prio=100,tag="_MIRROR_DIR","bind",loader.path.combine(loader.workdir,"build","mirror"),_MIRROR_DIR})
table.insert(sandbox.setup.mounts,{prio=100,tag="_SRC_DIR","bind",loader.path.combine(loader.workdir,"build","src"),_SRC_DIR})
table.insert(sandbox.setup.mounts,{prio=100,tag="_TMP_DIR","bind",loader.path.combine(loader.workdir,"build","tmp"),_TMP_DIR})
table.insert(sandbox.setup.mounts,{prio=100,tag="_CCACHE_DIR","bind",loader.path.combine(loader.workdir,"build","ccache"),_CCACHE_DIR})
table.insert(sandbox.setup.mounts,{prio=100,tag="_ZIP_DIR","bind",loader.path.combine(loader.workdir,"out"),_ZIP_DIR})
table.insert(sandbox.setup.mounts,{prio=100,tag="_LMANIFEST_DIR","bind",loader.path.combine(loader.workdir,"local_manifests"),_LMANIFEST_DIR})
table.insert(sandbox.setup.mounts,{prio=100,tag="_KEYS_DIR","bind",loader.path.combine(loader.workdir,"keys"),_KEYS_DIR})
table.insert(sandbox.setup.mounts,{prio=100,tag="_LOGS_DIR","bind",loader.path.combine(loader.workdir,"build","logs"),_LOGS_DIR})
table.insert(sandbox.setup.mounts,{prio=100,tag="_USERSCRIPTS_DIR","bind",loader.path.combine(loader.workdir,"userscripts"),_USERSCRIPTS_DIR})
table.insert(sandbox.setup.mounts,{prio=100,tag="_LSOURCES_DIR","bind",loader.path.combine(loader.workdir,"local_sources"),_LSOURCES_DIR})

-- custom package-names to include may be passed via command-line
build_packages=""
for arg_idx,arg_val in ipairs(loader.args) do
  build_packages=build_packages..arg_val.." "
end

-- just comment-out this whole block if sandbox not working because some of required utilities missing
-- currently, this params should work only with my setup
sandbox.bwrap_cmd={
  "netns-runner.sh", "vde_air", -- use my script to run sandbox inside separate network namespace
  "ionice","-c","3", -- set idle io-priority
  "nice","-n","19", -- set lowest CPU priority
  "taskset","--cpu-list","2,3,4,5,6,7,8,9,10,11,14,15,16,17,18,19,20,21,22,23", -- do not use 2 cores from my CPU for build, you config will be different
  "bwrap" -- main bwrap utility
}

-- modify built-in "shell" exec profile
shell.env_unset={"TERM","LANG","MAIL"}

-- define exec-profile that will build lineage os
build={
  exec="/bin/bash", -- TODO: change to /root/init.sh to run build right after invoke
  args={"-c","export PATH=\"/home/sandboxer/bin:$PATH\"; /root/init.sh"},
  path=_SRC_DIR,
  env_unset={"TERM","LANG","MAIL"},
  env_set={}, -- defined below
  term_signal=defaults.signals.SIGHUP,
  exclusive=true,
  attach=true,
  pty=true,
  term_on_interrupt=true,
  term_orphans=true, -- will forsefully stop all left-over tasks on exit
}

-- define some variables, needed for build scripts
build.env_set={
  {"TERM","xterm"},
  {"LANG","en_US.UTF-8"},

  -- define main ENV variables as in original Docker script
  {"MIRROR_DIR",_MIRROR_DIR},
  {"SRC_DIR",_SRC_DIR},
  {"TMP_DIR",_TMP_DIR},
  {"CCACHE_DIR",_CCACHE_DIR},
  {"ZIP_DIR",_ZIP_DIR},
  {"LMANIFEST_DIR",_LMANIFEST_DIR},
  {"KEYS_DIR",_KEYS_DIR},
  {"LOGS_DIR",_LOGS_DIR},
  {"USERSCRIPTS_DIR",_USERSCRIPTS_DIR},

  -- various config options
  {"USE_CCACHE","1"},
  {"CCACHE_SIZE","50G"},
  {"CCACHE_EXEC","/usr/bin/ccache"},
  {"BRANCH_NAME","lineage-17.1"}, -- OS version
  {"DEVICE_LIST","river"}, -- model of the device
  {"RELEASE_TYPE","CUSTOM"},
  {"OTA_URL",""},
  {"USER_NAME","buildbot"},
  {"USER_MAIL","sandbox@sandboxer.host"},
  {"INCLUDE_PROPRIETARY","true"}, -- absolutely must have
  {"LOCAL_MIRROR","false"},
  {"CLEAN_OUTDIR","false"},
  {"CLEAN_AFTER_BUILD","true"},
  {"WITH_SU","false"},
  {"ANDROID_JACK_VM_ARGS","-Dfile.encoding=UTF-8 -XX:+TieredCompilation -Xmx4G"},
  {"SIGN_BUILDS","true"},
  {"KEYS_SUBJECT","/C=US/ST=California/L=Mountain View/O=Android/OU=Android/CN=Android/emailAddress=android@android.com"},
  {"ZIP_SUBDIR","true"},
  {"LOGS_SUBDIR","true"},
  {"SIGNATURE_SPOOFING","restricted"},
  {"DELETE_OLD_ZIPS","0"},
  {"DELETE_OLD_LOGS","0"},

  -- do not change these (unsupported when running with sandboxer, or defined differently)
  {"BUILD_OVERLAY","false"}, -- not supported, do not change
  {"CRONTAB_TIME","now"}, -- not supported, do not change
  {"CUSTOM_PACKAGES",build_packages}, -- defined by passing package names via cmdline
}

-- shell profile will have same env as build profile
shell.env_set=build.env_set
