#! /usr/bin/perl -T

use strict;
use warnings;
use base qw(Test::Class);
use Test::Builder::Tester tests => 2;
use Test::More;

$ENV{TEST_VERBOSE}=0;

test_out("Bail out!  bailing out");
Test::Class->BAILOUT("bailing out");

END {
	test_test("bailout works");
	is($?, 255, "exit value okay");
	$?=0;
};
