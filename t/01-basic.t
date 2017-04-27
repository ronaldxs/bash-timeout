#!/usr/bin/env perl

use strict;
use warnings;

use Readonly;
use FindBin qw($Bin);
use File::Spec;

BEGIN {
    eval {require Capture::Tiny} ||
        die "Requires Perl module Capture::Tiny.  Please install from CPAN\n";
    Capture::Tiny->import('capture_merged');
}
use Test::More tests => 7;

Readonly our $RUN_CMD => "$Bin/../bin/timeout";
$ENV{B_TIMEOUT_IGNORE_CMD} = 1;

sub capture_s_merged {
    my @cmd = @_; # @_ not available in capture block
    my $x = capture_merged { system @cmd };
}

my $cmd_out = capture_s_merged "$RUN_CMD 3 bash -c 'sleep 1; echo awake'";
is $?, 0, 'test without timeout expiration 0 exit code';
like $cmd_out, qr/\Aawake\Z/, 'test without timeout expiration good output';

$cmd_out = capture_s_merged "$RUN_CMD 1 bash -c 'sleep 3; echo awake'";
is $?, 124 << 8, 'test with timeout expiration good exit code';
like $cmd_out, qr/^$/, 'test with timeout expiration good output';

if (capture_s_merged("find . -prune") eq ".\n") { # do we have UNIXish find
    subtest 'test descendent process kill with find', sub {
        plan tests => 2;
        Readonly my $SEARCH_DIR => File::Spec->catfile($Bin, 'find-two-test');
        Readonly my $SEARCH_DIR_FILE =>
            File::Spec->catfile($Bin, 'find-two-test', 'file-(?:one|two)');
        $cmd_out = capture_s_merged "$RUN_CMD 3 find $Bin/find-two-test -exec bash -c 'echo {}; sleep 2' \\;";
        is $?, 124 << 8, 'find with sleep per file timed out';
        like $cmd_out, qr/\A ^ $SEARCH_DIR $ \s* ^ $SEARCH_DIR_FILE $ \Z/mx,
            'find with timeout gave good output';
    };
}
else {
    subtest 'test descendent process kill with bash -c', sub {
        plan tests => 2;
        $cmd_out = capture_s_merged qq/$RUN_CMD 2 bash -c '
(sleep 4; echo "first awake")&
(sleep 4; echo "second awake")&
echo awake
wait
'/;
        is $?, 124 << 8, 'bash -c with background sub processes timed out';
        like $cmd_out, qr/\Aawake\Z/,
            'bash -c with sub processes right output';
    };
}

$cmd_out = capture_s_merged
    "bash -c 'f(){ sleep 1; echo \$1; }; export -f f; $RUN_CMD 3 f awake'";
is $?, 0, 'function without timeout expiration 0 exit code';
like $cmd_out, qr/\Aawake\Z/,
    'function without timeout expiration good output';
