#! /usr/bin/perl -T

use strict;
use warnings;
$ENV{TEST_VERBOSE}=0;

package Foo;
use Test::More;
use base qw(Test::Class);

sub darwin_only : Test {
	return("darwin only test");# unless $^O eq "darwin";
	ok(-w "/Library", "/Library writable") 
};

package main;
use Test::Builder::Tester tests => 1;

test_out("ok 1 # skip darwin only test");
Foo->runtests;
test_test("early return handled");
