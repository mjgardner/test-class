#! /usr/bin/perl -Tw

use strict;
use warnings;


package Foo;
use Test::More;
use base qw(Test::Class);

sub trailing_exception : Test(1) {
	pass("successful test");
	die "died\n";
};


package main;
use Test::Builder::Tester tests => 1;
$ENV{TEST_VERBOSE}=0;
test_out("ok 1 - successful test");
test_err("# trailing_exception died after test(s) with: died");
Foo->runtests;
test_test("trailing expection detected");
