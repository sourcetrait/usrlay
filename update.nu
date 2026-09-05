#!/usr/bin/env nu

const SRC_DIR: path = path self .

# Updates a user's overlay
export def main []: nothing -> nothing {
    let cfg_dir = ($nu.home-path | path join 'usrlay')
    if not ($cfg_dir | path exists) {
        error make $"usrlay is not configured on this system: ($cfg_dir)"
    }

    let cfg_dir_bak = $"($cfg_dir).bak"
    mv $cfg_dir $cfg_dir_bak

    let src_cfg_dir = ($SRC_DIR | path join 'config' 'nushell' 'usrlay')
    try {
        cp -r $src_cfg_dir $cfg_dir
    } catch {|e|
        if ($cfg_dir | path exists) {
            rm -rf $cfg_dir
        }

        mv $cfg_dir_bak $cfg_dir 
        print "restored previous usrlay config"

        error make { msg: $e.msg }
    }

    print "updated"
}
