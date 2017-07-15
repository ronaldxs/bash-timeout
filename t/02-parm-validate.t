#!/usr/bin/env perl

use strict;
use warnings;

use FindBin qw($Bin);
use File::Spec;
use IPC::Cmd qw(run_forked);

use Test::More tests => 4;

use constant RUN_CMD => "$Bin/../bin/timeout";
$ENV{B_TIMEOUT_IGNORE_CMD} = 1;

my $run_result;

SKIP: {
    $run_result = run_forked 'sleep zz';
    skip 'sleep does not validate duration parameter (eg mac)', 2 if ($run_result->{exit_code} == 0);
    $run_result = run_forked RUN_CMD . " zz echo hello";
    is $run_result->{exit_code}, 1, 'bad duration gives error exit code';
    like $run_result->{merged}, qr/invalid\b.*\bduration/,
        'bad duration gives helpful error message';
};

$run_result = run_forked RUN_CMD . " -sNONESUCH 2 echo hello";
is $run_result->{exit_code}, 1, 'bad signal gives error exit code';
like $run_result->{merged}, qr/invalid\b.*\bsignal/,
    'bad signal gives helpful error message';
