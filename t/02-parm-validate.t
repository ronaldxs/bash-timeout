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
use Test::More tests => 4;

Readonly our $RUN_CMD => "$Bin/../bin/timeout";
$ENV{B_TIMEOUT_IGNORE_CMD} = 1;

sub capture_s_merged {
    my @cmd = @_; # @_ not available in capture block
    my $x = capture_merged { system @cmd };
}

my $cmd_out;

SKIP: {
    capture_s_merged('sleep zz');
    skip 'sleep does not validate duration parameter (eg mac)', 2 if ($? == 0);
    $cmd_out = capture_s_merged("$RUN_CMD zz echo hello");
    is $?, 1 << 8, 'bad duration gives error exit code';
    like $cmd_out, qr/invalid\b.*\bduration/,
        'bad duration gives helpful error message';
};

$cmd_out = capture_s_merged("$RUN_CMD -sNONESUCH 2 echo hello");
is $?, 1 << 8, 'bad signal gives error exit code';
like $cmd_out, qr/invalid\b.*\bsignal/,
    'bad signal gives helpful error message';
