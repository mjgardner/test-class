#! /usr/bin/perl -T

use strict;
use warnings;
use Test::Builder::Tester;

package Local::Test;
use base qw(Test::Class);
use Test::More;

sub test : Test( 1 ) {
	pass("it works");
};

package main;
use Test::More 'no_plan';
$ENV{TEST_VERBOSE}=0;
test_out("ok 1 - it works");
Local::Test->runtests;
test_test("can have spaces around attributes");
print "1..1\n";
