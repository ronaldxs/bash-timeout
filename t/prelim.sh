#!/usr/bin/env bash

function f {
    echo called f
    echo griddle
    echo waddle
    echo puddle
    echo "$@"
    sleep 4
}

function timely {
    local time_limit=5

    if [[ -n $1 && -z ${1//[0-9]} ]] ; then
        time_limit=$1
        shift
    fi

    $(dirname "$0")/../bin/b_timeout $time_limit "$@"
}

export TIMEOUT_IGNORE_CMD=1
export -f f
timely 5 bash -c "f whistle bustle"
echo $? after f
timely 2 bash -c "f whistle bustle"
echo $? after f

sudo bash -c "echo 3 >/proc/sys/vm/drop_caches"
echo before find
timely 2 bash -c "find / '*.pl' >/dev/null"
echo $? after find

timely 5 ls -l
echo $? after ls
# dup parent stderr
# redirect parent stderr to /dev/null
# redirect child stderr to dup
# redirect parent stderr to dup
# close dup
