# Internals

## Why this program

I needed a process timeout function for another utility that was to be coded
in bash.  GNU timeout works fine for Linux (and some others) but seems
not to be part of default Mac OS installation and it looked easy enough
to code a bash/POSIX solution.  It was not as easy as I thought but the
complexity of the current solution seems acceptable.

## Trivial bash solution and limitations

I looked through the forums for a solution and saw GNU timeout and
several solutions that looked like:

    prog & sleep 10; kill $!

As some noted this shell solution only kills the starting process/pid for
"prog" but not necessarily child processes.  You may not know whether your
program forks and, for shell scripting, forking may be more common than
expected.

In the following two examples there seems to be no fork and the hack works.

    perl -e 'sleep 3; print "hello\n"' & sleep 1; kill $!
    bash -c 'perl -e "sleep 3; print \"hello\n\""' & sleep 1; kill $!

In the next two examples there seems to be a fork and the hack fails.

    bash -c 'perl -e "sleep 3; print \"hello\n\""; sleep 1' & sleep 1; kill $!
    bash -c 'perl -e "sleep 3; print STDERR \"hello\n\"" >/dev/null' &
        sleep 1; kill $!

The first failing example has bash running two steps and bash forks to run
the first step so that it can process the next step when the perl script
finishes.  The second example has only one step but bash appears to fork
before running the program, likely, so that bash's own output handles are
still available.  Note that `perl`'s output handle has to be redirected before
`perl` starts running.  Perl solutions that look like:

    perl -e 'alarm shift; exec @ARGV' --

have the same problem as the trivial bash solution. (Believed to apply to
http://mywiki.wooledge.org/BashFAQ/068)

## More complete solutions

GNU timeout handles child processes by setting a new process group id and
sending kill signals to the process group.  This shell solution could not do
that and uses `ps` to look through parent/child pid relationships and signal
all descendants.  The process group approach suggests a more complete Perl
solution that is only a little more complicated.  There is also an existing
[timeout.pl](http://www.cpan.org/authors/id/D/DE/DEXTER/timeout-0.11.pl)
Perl/CPAN script.

    doalarm() {
        perl -e '
            local $SIG{ALRM} = sub { kill "TERM", 0 };
            setpgrp;
            alarm shift;
            system @ARGV;
        ' -- "$@"
    }

## bash solution does not implement -k

The technique used to suppress the Terminated message for `TERM` in this bash
approach also suppresses Killed message for `KILL`.  GNU timeout seems to
solve this problem by sending signals to the process group but trapping the
`TERM` signal in the timeout program.  Working around the difference seemed
too complicated and -k is not implemented in the bash replication at this
time.
