#! /usr/bin/perl -T

use strict;
use warnings;
use base qw(Test::Class);
use Test::More tests => 2;
use Test::Builder::Tester;

$ENV{TEST_VERBOSE}=0;

test_out("not ok 1 - failing");
test_out("not ok 2 - failing");
test_fail(+2);
test_fail(+1);
Test::Class->FAIL_ALL("failing");

END {
	test_test("FAIL_ALL with plan");
	is($?, 2, "exit value okay");
	$?=0;
};
