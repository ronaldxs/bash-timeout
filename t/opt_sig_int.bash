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

    $(dirname "$0")/../bin/b_timeout -p -sINT $time_limit "$@"
}

export B_TIMEOUT_IGNORE_CMD=1
export -f f
timely 2 bash -c "f whistle bustle"
echo $? after f

