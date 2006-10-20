#! /usr/bin/perl -T

use strict;
use warnings;
use Test;
use Test::Builder::Tester tests => 1;

package Object::Test;
use base 'Test::Class';
use Test::More;

sub setup : Test(setup) {
	die "died before plan set\n";
};

sub test : Test {
	ok(1==1, 'test just here to get setup method run');
};


package main;

$ENV{TEST_VERBOSE}=0;

test_out("not ok 1 - setup (for test method 'test') died (died before plan set)");
test_fail(+3);
test_err( "#   (in Object::Test->setup)" );
test_out("ok 2 - test just here to get setup method run");
Object::Test->runtests;
test_test("die before plan");
