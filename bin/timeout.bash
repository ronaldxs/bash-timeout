#!/usr/bin/env bash

# timeout - bash implementation of gnu timeout
# Copyright (C) Ronald Schmidt
# GPL License should be included in source repository.

list_process_tree ()
{
    local IFS=$'\n'
    local p="$1"
    local monitor="$2" # recursive calls have no $2
    # child processes ppid="$p"
    local -a children=($(ps -o ppid= -o pid= |
        grep '^[ '$'\t'"]*$p\b" |
        sed 's/[[:blank:]]]*[0-9][0-9]*[[:blank:]][[:blank:]]*\([0-9][0-9]*\)/\1/'
    ))
    if [[ ${monitor:+1} ]] ; then
        children=($(echo "${children[*]}" | grep -v "\b$monitor\$"))
    fi

    for pid in "${children[@]}"
    do
        list_process_tree "$pid"
    done

    echo "$p"
}

[[   -z $TIMEOUT_IGNORE_CMD         &&
     -n $(type -p timeout 2>&1)
]] || function timeout {
    echo in bash timeout

    local exit_code time_limit=$1 prog=$2 timeout_marker
    shift 2
    if [[ -z $TIMEOUT_NO_RC_124 ]]; then
        timeout_marker=$(
            mktemp -q ||
            mktemp -q -t "$(basename "$0").XXXXXX"
        )
        if [[ -n ${timeout_marker:+1} ]]; then
            trap 'if [[ -e $timeout_marker ]]; then rm "$timeout_marker"; fi' EXIT
        fi
    fi

    exec 3>&2
    exec 2>/dev/null # suppress report of child process death
    (
        exec 2>&3 # normal stderr for sub process
        mainpid=$(sh -c 'echo $PPID')
        (
            sleep $time_limit
            monitor_pid=$(sh -c 'echo $PPID')
#            ps

            # remove not reliable after kill - race condition
            if [[ -n ${timeout_marker:+1} ]]; then
                rm "$timeout_marker"
            fi

            kill $(list_process_tree $mainpid $monitor_pid)
        ) &
        watchdogpid=$!
        ${prog} "$@"
        exit_code=$?
        kill $watchdogpid
        exit $exit_code
    )
    exit_code=$?

    exec 2>&3 # restore stderr
    exec 3>&- # close dup stderr

    if [[ -n ${timeout_marker:+1} ]]; then
        if [[ -e $timeout_marker ]]; then
            rm $timeout_marker
        elif [[ $exit_code -ne 0 ]]; then
            exit_code=124
        fi
    fi

#    ps
    return $exit_code
}

