#!/usr/bin/env perl

use strict;
use warnings;

use Readonly;
use FindBin qw($Bin);
use File::Spec;
use IPC::Cmd qw(run_forked); # remove run later
use Data::Dumper;
$|++;

use Test::More tests => 7;

# use constant and concat
use constant RUN_CMD => "$Bin/../bin/timeout";
$ENV{B_TIMEOUT_IGNORE_CMD} = 1;


my $run_result = run_forked RUN_CMD . " 3 bash -c 'sleep 1; echo awake'";
is $run_result->{exit_code}, 0, 'test without timeout expiration 0 exit code';
like $run_result->{merged}, qr/\Aawake\Z/,
    'test without timeout expiration good output';

$run_result = run_forked RUN_CMD . " 1 bash -c 'sleep 3; echo awake'";
is $run_result->{exit_code}, 124, 'test with timeout expiration good exit code';
like $run_result->{merged}, qr/^$/, 'test with timeout expiration good output';

$run_result = run_forked 'find . -prune';
if ($run_result->{merged} eq ".\n") { # do we have UNIXish find
    subtest 'test descendent process kill with find', sub {
        plan tests => 2;
        my $search_dir = File::Spec->catfile($Bin, 'find-two-test');
        my $search_dir_file =
            File::Spec->catfile($Bin, 'find-two-test', 'file-(?:one|two)');
        $run_result = run_forked RUN_CMD . " 3 find $Bin/find-two-test -exec bash -c 'echo {}; sleep 2' \\;";
        is $run_result->{exit_code}, 124, 'find with sleep per file timed out';
        like $run_result->{merged}, qr/\A ^ $search_dir $ \s* ^ $search_dir_file $ \Z/mx,
            'find with timeout gave good output';
    };
}
else {
    subtest 'test descendent process kill with bash -c', sub {
        plan tests => 2;
        $run_result = run_forked RUN_CMD . qq/ 2 bash -c '
(sleep 4; echo "first awake")&
(sleep 4; echo "second awake")&
echo awake
wait
'/;
        is $run_result->{exit_code}, 124, 'bash -c with background sub processes timed out';
        like $run_result->{merged}, qr/\Aawake\Z/,
            'bash -c with sub processes right output';
    };
}

$run_result = run_forked
    "bash -c 'f(){ sleep 1; echo \$1; }; export -f f; " . RUN_CMD .
        " 3 f awake'";
is $run_result->{exit_code}, 0, 'function without timeout expiration 0 exit code';
like $run_result->{merged}, qr/\Aawake\Z/,
    'function without timeout expiration good output';
