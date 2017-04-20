#!/usr/bin/env bash

# timeout - bash implementation of gnu timeout
# Copyright (C) Ronald Schmidt
# GPL License should be included in source repository.

# overkill for systems like cygwin (supports timeout anyway) without POSIX ps
# ps -f starts with UID, PID, PPID
# for fancier parsing allowing UID with space we find end of PPID column
_b_timeout_precompute_ps_f_prefix () {
    if ! ps -p "$$" -o ppid= >/dev/null 2>&1; then
        local header_line=$(ps -f -p "$$" | head -1);
        header_line="${header_line%%PPID*}"
        # length of title line up to end of PPID column title
        # ps pids seem to right align with columnt titles
        echo $(( ${#header_line} + 4 ))
    fi
}

# overkill for systems like cygwin (supports timeout anyway) without POSIX ps
_b_timeout_child_pid_ps_f () {
    ps -f | tail -n+2 |
        sed "s/^.\{1,$_precomp_ps_f_prefix\}\b\([0-9][0-9]*\)[ \t][ \t]*\([0-9][0-9]*\)\b.*/\2 \1/"
}

list_process_tree ()
{
    local IFS=$'\n'
    local p="$1"
    local monitor="$2" # recursive calls have no $2

    # child processes ppid="$p"
    local -a pid_by_parent
            echo misery two >&2
            echo $_precomp_ps_f_prefix >&2
    if ! (( $_precomp_ps_f_prefix )) ; then # if POSIXy ps
        pid_by_parent=($(ps -o ppid= -o pid=))
    else
        pid_by_parent=($(_b_timeout_child_pid_ps_f))
    fi
    local -a children=($(echo "${pid_by_parent[*]}" |
            grep '^[ '$'\t'"]*$p\b" |
            cut -d' ' -f2
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
            _precomp_ps_f_prefix="$(_b_timeout_precompute_ps_f_prefix)"

            sleep $time_limit

            echo misery one >&2
            echo $_precomp_ps_f_prefix >&2

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

