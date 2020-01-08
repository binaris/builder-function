function github_branch_exists() {
    # the installer-base image is generated in aether
    # the rest of the images are generated in their base name repo
    # for example:
    # marathon-redis-installer image is in marathon repo,
    # and spice image is in spice repo.
    org=binaris
    if [ "$1" == "installer-base" ]; then
        repo=aether
    elif [ "$1" == "reshuffle" ]; then
        repo=reshuffle
        org=reshufflehq
    else
        repo=$(echo $1 | perl -pe 's/(-redis)?-installer//' | perl -pe 's/-radio//')
    fi
    branch=$2
    echo "Looking for git branch ${repo} ${branch}"
    rv=$(git ls-remote --heads git@github.com:${org}/${repo}.git ${branch} 2>/dev/null | wc -l)
    return $(($rv != 1))
}
