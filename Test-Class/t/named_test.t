#! /usr/bin/perl -T

use strict;
use warnings;
use Test::Builder::Tester;

package Local::Test;
use base qw(Test::Class);
use Test::More;

sub default_name : Test( 1 ) {
	pass();
};

package main;
use Test::More 'no_plan';
$ENV{TEST_VERBOSE}=0;
test_out("ok 1 - default name");
Local::Test->runtests;
test_test("test names set to method name by default");
print "1..1\n";
