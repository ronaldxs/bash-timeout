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
use Test::More tests => 2;

Readonly our $RUN_CMD => "$Bin/../bin/timeout";
$ENV{B_TIMEOUT_IGNORE_CMD} = 1;

sub capture_s_merged {
    my @cmd = @_; # @_ not available in capture block
    my $x = capture_merged { system @cmd };
}

my $cmd_out = capture_s_merged
    "$RUN_CMD -p -sINT 2 bash -c 'echo hello; sleep 3; echo awake'";
is $?, (128 + 2) << 8, 'good exit code for INT signal';
like $cmd_out, qr/\Ahello\Z/, 'good interrupt output';
