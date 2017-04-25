#A/usr/bin/env bash

export B_TIMEOUT_IGNORE_CMD=1
cmd=$(dirname "$0")/../bin/b_timeout
$cmd a2bc echo hello
echo exit code $?
$cmd 1 echo hello
echo exit code $?

$cmd -sNONESUCH 2 echo hello
echo exit code $?
$cmd -sINT 2 echo hello
echo exit code $?
