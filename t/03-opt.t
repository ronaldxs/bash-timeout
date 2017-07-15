#!/usr/bin/env perl

use strict;
use warnings;

use FindBin qw($Bin);
use File::Spec;
use IPC::Cmd qw(run_forked);

use Test::More tests => 2;

use constant RUN_CMD => "$Bin/../bin/timeout";
$ENV{B_TIMEOUT_IGNORE_CMD} = 1;

my $run_result = run_forked RUN_CMD .
    " -p -sINT 2 bash -c 'echo hello; sleep 3; echo awake'";
is $run_result->{exit_code}, (128 + 2), 'good exit code for INT signal';
like $run_result->{merged}, qr/\Ahello\Z/, 'good interrupt output';
