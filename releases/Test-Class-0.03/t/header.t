#! /usr/bin/perl -w

use strict;
use Test::Builder::Tester;

package Local::Test;
use base qw(Test::Class);
use Test::More;

sub test : Test {
	pass("test in Test::Class");
};

package main;
use Test::More 'no_plan';
test_out("ok 1 - test in Test::Class");
Local::Test->runtests;
{
	local $TODO = "todo";
	test_test("no duplicate headers");
};
print "1..1\n";
