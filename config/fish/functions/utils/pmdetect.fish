function pmdetect --description "Returns npm, yarn, pnpm, or bun if they are used in the current project"
    set -l cache_file .git/package_manager_cache; and mkdir -p .git
    set -l lockfiles "yarn.lock" "package-lock.json" "pnpm-lock.yaml" "bun.lockb"
    set -l managers yarn npm pnpm bun

    # check if we have a cached result
    if test -f $cache_file
        cat $cache_file
        return 0
    end

    # check for lock files
    for i in (seq (count $lockfiles))
        if test -f $lockfiles[$i]
            echo $managers[$i] | tee $cache_file
            return 0
        end
    end

    # check for installed package managers
    for manager in yarn pnpm bun
        if command -q $manager
            echo $manager | tee $cache_file
            return 0
        end
    end

    # default to npm
    echo npm | tee $cache_file
    return 0
end
