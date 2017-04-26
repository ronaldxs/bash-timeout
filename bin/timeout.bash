#!/usr/bin/env bash

# timeout - bash implementation of gnu timeout
# Copyright (C) Ronald Schmidt
# GPL License should be included in source repository.

# no set_pgrp and no asychronous wait

if ! [[
    -z $B_TIMEOUT_IGNORE_CMD    &&
    -n $(type -p timeout 2>&1)
]] ; then

# only define functions if no timeout program or specified override

function _b_timeout_list_process_tree {
    local IFS=$'\n'
    local p="$1"
    local monitor="$2" # recursive calls have no $2
    # child processes ppid="$p"
    local -a children=($(ps -o ppid= -o pid= |
        grep '^[ '$'\t'"]*$p\b" |
        sed 's/[[:blank:]]*[0-9][0-9]*[[:blank:]][[:blank:]]*\([0-9][0-9]*\)/\1/'
    ))
    if [[ ${monitor:+1} ]] ; then
        children=($(echo "${children[*]}" | grep -v "\b$monitor\$"))
    fi

    for pid in "${children[@]}"
    do
        echo "$pid"
        _b_timeout_list_process_tree "$pid"
    done
}

# The part of bash timeout after argument processing
function _b_timeout_main {
#    echo in bash timeout

    local exit_code time_limit=$1 prog="$2" timeout_marker kill_monitor_pid
    shift 2

    # create timeout marker file whose presenc will cause 124 exit code later
    # unless opt out with -p option or environment
    if [[ -z $b_lcl_is_preserve_exit && -z $B_TIMEOUT_NO_RC_124 ]]; then
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
            kill $b_lcl_alt_signal $(
                _b_timeout_list_process_tree $mainpid $monitor_pid
            ) $mainpid
        ) &
        watchdogpid=$!
#        echo `date` before prog >>/tmp/xx
        "$prog" "$@"
        exit_code=$?
#        echo `date` after prog >>/tmp/xx
        kill $watchdogpid
#        echo $(date) kill watchdog >>/tmp/xx
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

    return $exit_code
}

function timeout {
    local b_lcl_timeout_to_kill b_lcl_alt_signal b_lcl_is_preserve_exit 

    while getopts ps: opt; do
        case "$opt" in
            p)  b_lcl_is_preserve_exit=1
                ;;
            s)  b_lcl_alt_signal="-$OPTARG"
                sleep 3 & # just to validate kill signal
                if ! kill "$b_lcl_alt_signal" $! ; then
                    echo Validation of signal for '-s' option failed. >&2
                    return 1
                fi 
                ;;
        esac
    done
    shift $((OPTIND-1))

    # test timeout duration by sleeping with zeroed out duration
    if ! sleep "${1//[1-9]/0}" ; then
        echo invalid timeout duration: >&2
        echo $'\t'Duration incompatible with sleep after substituting 0 for digits.>&2
        return 1;
    fi
    _b_timeout_main "$@"
}

fi # end test for use existing timeout program at top of file
