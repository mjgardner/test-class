#! /usr/bin/perl -T

use strict;
use warnings;
use base qw(Test::Class);
use Test::More 'no_plan';
use Test::Builder::Tester;

$ENV{TEST_VERBOSE}=0;

test_out("ok 1 - passing");
pass("passing");
test_out("not ok 2 - failing");
test_fail(+1);
Test::Class->FAIL_ALL("failing");

END {
	test_test("FAIL_ALL with no plan");
	is($?, 1, "exit value okay");
	print "1..2\n";
	$?=0;
};
