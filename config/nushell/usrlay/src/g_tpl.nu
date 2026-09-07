# Creates a new Git repository using '.repo' templates.
export def --env 'g new' [
    dir: directory,
    --user: string = 'default',
    --license: string = 'default',
    --readme: string = 'default',
    --ignore: string = 'default',
]: nothing -> nothing {
    g_new $dir --user $user --license $license --readme $readme --ignore $ignore
    cd $dir
}

def g_new [
    dir: directory,
    --user: string = 'default',
    --license: string = 'default',
    --readme: string = 'default',
    --ignore: string = 'default',
]: nothing -> nothing {
    if ($dir | path exists) {
        error make --unspanned $"directory already exists: ($dir)"
    }
    
    let user_tpl = ((dotrepo 'g/user') | tpl expand suffix '.config' $user)
    let license_tpl = ((dotrepo 'g/license') | tpl expand link $license)
    let readme_tpl = ((dotrepo 'g/readme') | tpl expand prefix 'README' '.md' $readme)
    let ignore_tpl = ((dotrepo 'g/ignore') | tpl expand suffix '.gitignore' $ignore)

    mkdir $dir
    cd $dir
    git init -q .

    open --raw $user_tpl.src | save --append '.git/config'

    cp $ignore_tpl.src $ignore_tpl.dst
    cp $license_tpl.src $license_tpl.dst
    cp $readme_tpl.src $readme_tpl.dst

    git add . | ignore -xo
    git commit -m 'init' | ignore -xo
}

def 'tpl srcdst' [dir: directory]: path -> record<src: path, dst: path> {
    let src: path = $in

    let dst_path = $"($src).dst"
    if ($dst_path | path exists) {
        let $dst = open --raw $dst_path | lines | first | default '' | str trim
        if $dst != '' {
            return { src: $src, dst: $dst }
        }
    }

    let dst_path = ($dir | path join 'default.dst')
    if ($dst_path | path exists) {
        let $dst = open --raw $dst_path | lines | first | default '' | str trim
        if $dst != '' {
            return { src: $src, dst: $dst }
        }
    }

    { src: $src, dst: ($src | path basename) }
}

def 'tpl expand suffix' [ext: string, tpl: string, --option]: directory -> oneof<nothing, record<src: path, dst: path>> {
    let dir: directory = $in | path expand
    let src = if $tpl == 'default' {
        $dir | path join 'default' | path expand
    } else {
        $dir | path join $"($tpl)($ext)" | path expand
    }

    if ($src | path exists) {
        $src | tpl srcdst $dir
    } else if not $option {
        error make --unspanned $"dotrepo template not found: ($src)"
    } else {
        null
    }
}

def 'tpl expand link' [tpl: string, --option]: path -> oneof<nothing, record<src: path, dst: path>> {
    let dir: directory = $in | path expand
    let src = if $tpl == 'default' {
        $dir | path join 'default' | path expand
    } else {
        $dir | path join $"($tpl).link" | path expand
    }

    if ($src | path exists) {
        $src | tpl srcdst $dir
    } else if not $option {
        error make --unspanned $"dotrepo template not found: ($src)"
    } else {
        null
    }
}

def 'tpl expand prefix' [prefix: string, ext: string, tpl: string, --option]: path -> oneof<nothing, record<src: path, dst: path>> {
    let dir: directory = $in | path expand
    let src = if $tpl == 'default' {
        $dir | path join 'default' | path expand
    } else {
        $dir | path join $"($prefix).($tpl)($ext)" | path expand
    }

    if ($src | path exists) {
        $src | tpl srcdst $dir
    } else if not $option {
        error make --unspanned $"dotrepo template not found: ($src)"
    } else {
        null
    }
}

# finds a '.repo/$subdir' in the parent path hierarchy
export def dotrepo [subdir: directory, --option]: nothing -> oneof<nothing, directory> {
    mut curdir = (pwd)

    loop {
        let repodir = ($curdir | path join '.repo' $subdir | path expand)
        if ($repodir | path exists) {
            return $repodir
        }

        let dir = ($curdir | path join '..' | path expand)
        if not ($dir == $curdir) {
            $curdir = $dir
        } else if not $option {
            error make --unspanned $"dotrepo not found in parent hierarchy: .repo/($subdir)"
        } else {
            return null
        }
    }
}
