#!/bin/sh
#
# This is not a source file
# The source can be found in the repo :
#    http://<user>@git/scm/dev/dalidevbuild.git
#
# Local modifications will be discarded
#
#
# start Docker and connect
#
# To test an updated version of the environment set TAG in Makefile and run this script
#
# TAG=<updated_tag> ./runDaliDev.sh
#
# That will force it to load the updated image in the local cache.
#
progname=`basename $0`
NOUPDATE=no
: ${TAG:=12}

user=`id -un | sed 's/ /_/g' 2> /dev/null`
uid=`id -u 2> /dev/null`
group=`id -gn | sed 's/ /_/g' 2> /dev/null`
gid=`id -g 2> /dev/null`

#
# Add docker in docker support if the docker command
# is present in the Makefile
#
dockerindocker='no'
if [ -f Makefile.am ] ; then
    if grep -q 'docker' Makefile.am ; then
        dockerindocker='yes'
    fi
fi
if [ -f Makefile ] ; then
    if grep -q 'docker' Makefile ; then
        dockerindocker='yes'
    fi
fi
if [ -f Gruntfile.js ] ; then
    if grep -q 'docker' Gruntfile.js ; then
        dockerindocker='yes'
    fi
fi

if [ "x$user" = "x" -o "x$user" = "x$uid" ] ; then
    user=builder
fi

if [ "x$group" = "x" -o "x$group" = "x$gid" ] ; then
    group=builder
fi

user=`echo $user | tr '[:upper:]' '[:lower:]'`
group=`echo $group | tr '[:upper:]' '[:lower:]'`
containerdir="/home/$user"
workdir='/home/work'
hostdir="$PWD"
hosthome="$HOME"
SSHKEYGEN='ssh-keygen'

case $(uname) in
    MING*)
        userprofile=`cygpath $USERPROFILE`
        if [ $userprofile != $HOME ] ; then
            HOME=$userprofile
            hosthome=$HOME
        fi
        SSHKEYGEN=ssh-keygen.exe
        dockergid=$(id -g docker-users)
        dockersock='/var/run/docker.sock'
        if [ -f "/c/Program Files/Docker/Docker/Docker for windows.exe" ] ; then
            hostdir=$(cygpath -w $hostdir)
            hosthome=$(cygpath -w $hosthome)
            workdir='//home/work'
            dockersock='//var/run/docker.sock'
        fi
        ;;
    CYGWIN_NT-10.0)
        # For windows 10 running Docker for Windows
        #  Note: Docker Toolbox is not supported
        hostdir=$(cygpath -w $hostdir) 
        userprofile=`cygpath $USERPROFILE`
        if [ $userprofile != $HOME ] ; then
            HOME=$userprofile
	    hosthome=$HOME
        fi
        hosthome=$(cygpath -w $hosthome)
        SSHKEYGEN=ssh-keygen.exe
        dockergid=$(id -g docker-users)
        dockersock='//var/run/docker.sock'
        ;;
    CYGWIN*)
        userprofile=`cygpath $USERPROFILE`
        if [ $userprofile != $HOME ] ; then
            HOME=$userprofile
            containerdir=/home/builder
        fi
        SSHKEYGEN=ssh-keygen.exe
        dockergid=50
        dockersock='/c/var/run/docker.sock'
        ;;
    Linux)
        dockergid=`getent group docker | awk -F: '{print $3}'`
        dockersock='/var/run/docker.sock'
        ;;
    Darwin)
        dockergid=50
        dockersock='/var/run/docker.sock'
        ;;
esac

usage()
{
    cat << __EOF

"$progname" run the command CMD in the dali-dev docker build environment, if CMD is omitted
    the command /bin/bash is run instead. All commands are run as the current UID and GID,
    the following environment variables and volumes are passed to the container:

            Mounted Volumes:
                $HOME is mounted as $containerdir
                $PWD is mount as $workdir

            Environment Variables:
                USER=$user
                UID=$uid
                GROUP=$group
                GID=$gid

    If the key ~/.ssh/daligit is not found, a new key is created and copied to the git server.
    The '-s' option can be used to force the git SSH setup to be rerun. All old keys are destroyed.

Usage $progname [OPTIONS] [CMD]

Optional arguments:
 -b             don't use interactive terminal, for doing builds
 -c REPO        clone REPO url for working Alpine repo (fast)
 -C BRANCH      create working Alpine repo from scratch using git BRANCH (go for lunch slow)
                (if BRANCH exists in DevOps repos, it is used, otherwise master is used)
 -d             delete the working alpine repo and exit
 -f             force the working alpine repo to be recreated
 -h             this help message
 -n             don't check for or pull updated images
 -u TAG         updates dev-build docker image to version TAG
 -R NAME        user repo name NAME, default is to use USER name
                - if the environment variable DALI_REPO is set, it will take precedence
 -s             Force git SSH key setup to run again
 -t             print the current docker tag and exit
 -v             print the version and exit
 -x             trace execution of $progname,
                if two x options are present then daliDevEnv.sh
                is also traced
__EOF
}

die() { 
    echo "$@" 1>&2
    exit 1
}

setup_git_ssh()
{
    [ -d $HOME/.ssh ] || mkdir $HOME/.ssh

    add_host=yes
    if [ -f $HOME/.ssh/config ] ; then
        if grep -q "git.dali.local" $HOME/.ssh/config ; then
            add_host=no
        fi
    fi
    if [ $add_host = yes ] ; then
        cat << __EOF >> $HOME/.ssh/config
Host git git.dali.local
    IdentityFile ~/.ssh/daligit
    ForwardX11 no
    ForwardX11Trusted no
    StrictHostKeyChecking no
__EOF
    fi
    $SSHKEYGEN -P "" -f $HOME/.ssh/daligit
    chmod -R u=rwX,go= $HOME/.ssh
}

fix_docker_credstore()
{
    if [ -f $HOME/.docker/config.json ] ; then
        sed -i.bak '/credsStore/s/:.*$/: ""/' $HOME/.docker/config.json
        chmod 600 $HOME/.docker/config.json
    fi
}

printversion()
{
    version='$Id: 941061c39742729430acefd249d4b538b50bc5fd $'
    echo $version | awk '{print $2}'
    exit 0
}

printtag()
{
    echo $TAG
    exit 0
}

check_for_updates() {
    if [ $NOUPDATE = 'yes' ] ; then
        return
    fi

    printf "\nchecking for updates....\n"
    updates='no'
    n=$TAG
    while true
    do
        n=`expr $n + 1`
        if ! docker inspect --format "{{.Id}}" dockrepo.dali.local/dev-build:$n > /dev/null 2>&1 ; then
            break
        fi
        updates='yes'
        printf "\tversion $n of dev-build is available\n"
    done
    printf "\n"

    if [ $updates = 'no' ] ; then
        printf "\tdev-build is up to date\n"
    else
        printf "to update to 12 use command:\n"
        printf "\n\t./runDaliDev.sh -u 12\n\n"
        printf "to update to version N use command:\n"
        printf "\n\t./runDaliDev.sh -u N\n\n"
        printf "the final form can be used to downgrade as well\n"
        printf "downgrading below version 8 will result in the loss of this update feature\n"
    fi
    printf "\n"
}

#
# Process options and arguments
#
opt_b='no'
opt_C=''
opt_c=''
opt_d='no'
opt_f='no'
opt_n='no'
opt_R="$USER"
opt_s='no'
opt_u=$TAG
opt_x=0
while getopts bC:c:dfhnR:stu:vx c
do
    case $c in
    b) opt_b='yes' ;;
    C)
        opt_C=$OPTARG
        dockerindocker='yes'
        ;;
    c) opt_c=$OPTARG ;;
    d) opt_d='yes' ;;
    f) opt_f='yes' ;;
    h) usage ; exit 0 ;;
    n) opt_n='yes' ;;
    R) opt_R=$OPTARG ;;
    s) opt_s='yes' ;;
    t) printtag ;;
    u) opt_u=$OPTARG ;;
    v) printversion ;;
    x) opt_x=`expr $opt_x + 1` ; set -x ;;
    \?) usage ; die "unknown option" ;;
    esac
done

shift $(($OPTIND - 1))

if [ -n "$opt_c" -a -n "$opt_C" ] ; then
    die "only one of \"-c REPO\" or \"-C BRANCH\" should be used, not both"
fi

#
# only check for updates if
# an update hasn't been requested
#
if [ $opt_n = 'no' -a $opt_u = $TAG ] ; then
    check_for_updates
fi

if [ ! -f $HOME/.ssh/daligit ] ; then
    opt_s='yes'
fi

if [ "$opt_s" = 'yes' ] ; then
    setup_git_ssh
fi

fix_docker_credstore

if [ $opt_n = 'no' ]; then
    docker pull dockrepo.dali.local/dev-build:$opt_u
fi

dockerargs=' -it '
if [ "$opt_b" = 'yes' ] ; then
    dockerargs=''
fi
if [ $dockerindocker = 'yes' ] ; then
    dockerargs="$dockerargs -v $dockersock:/var/run/docker.sock"
    dockerargs="$dockerargs -e DOCKER_GID=$dockergid"
fi

: ${DALI_REPO:=$opt_R}

#
# The error exit must be on the same line as the command
# this prevents erroneous error messages if the container
# updates this script while it is being run
#
docker run --rm \
    -e XTRACE=$opt_x \
    -e USER=$user \
    -e UID=$uid \
    -e GROUP="$group" \
    -e GID=$gid \
    -e opt_c=$opt_c \
    -e opt_C=$opt_C \
    -e opt_d=$opt_d \
    -e opt_f=$opt_f \
    -e DALI_REPO=$DALI_REPO \
    -e DALI_HOSTDIR="$hostdir" \
    -e hostuname=$(uname) \
    -v "$hosthome":$containerdir:delegated \
    -v "$hostdir":$workdir:cached \
    -w $workdir \
    --net=host \
    --privileged \
    $dockerargs \
    dockrepo.dali.local/dev-build:$opt_u "$@" || exit $?

exit 0
