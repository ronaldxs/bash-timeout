# NAME

timeout - Send a TERM (or other) signal after a specified duration
to a command if the command has not already completed.  Like GNU timeout
but supplies bash function implementation of timeout if check
for GNU timeout fails.  The duration is passed to "sleep" and so can
be any value accepted by your system sleep command.

# SYNOPSIS

    $ timeout 2 bash -c 'echo abc; sleep 3; echo def'
    abc
    $ echo $?
    124

## Switches

- **-p**

    Preserve exit code from signalled process.  If bash timeout tried to end
    its command with a signal after the timeout duration the exit code is
    normally 124.  The **-p** option requests that bash timeout use the exit
    code of the signalled process which should usually be 128+(signal number).

- **-s**

    Alternative signal to be passed to kill if you want a signal other
    than TERM after the duration expires.  Again any value accepted by
    your system kill should work but do not pass a leading '-' (so
    \-sINT and not -s-INT).
