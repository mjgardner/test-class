#! /usr/bin/perl -T

use strict;
use warnings;
$ENV{TEST_VERBOSE}=0;

package Foo;
use Test::More;
use base qw(Test::Class);

sub extra_test : Test(1)  {
	ok(1, "expected test");
	ok(1, "extra test");
};

package main;
use Test::Builder::Tester tests => 1;

test_out("ok 1 - expected test");
test_out("ok 2 - extra test");
test_err("# expected 1 test(s) in extra_test, 2 completed");
Foo->runtests;
test_test("extra test detected");
