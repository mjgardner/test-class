#! /usr/bin/perl -T

use strict;
use warnings;

use Test::Builder::Tester;

package Local::Test;
use base qw(Test::Class);
use Test::More;

sub test : Test {
	pass("test in Test::Class");
};

package main;
use Test::More 'no_plan';
$ENV{TEST_VERBOSE}=0;
test_out("ok 1 - test in Test::Class");
Local::Test->runtests;
test_test("no duplicate headers");
print "1..1\n";
