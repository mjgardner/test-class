#! /usr/bin/perl -T

use strict;
use warnings;
$ENV{TEST_VERBOSE}=0;

package Foo;
use Test::More;
use base qw(Test::Class);

sub darwin_only : Tests(2) {
    return("darwin only test");# unless $^O eq "darwin";
    ok(-w "/Library", "/Library writable");
    ok(-r "/Library", "/Library readable");
};

package Bar;
use Test::More;
use base qw(Test::Class);

sub fail_if_returned_early { 1 }

sub darwin_only : Tests(2) {
    return("darwin only test");# unless $^O eq "darwin";
    ok(-r "/Library", "/Library readable");
    ok(-w "/Library", "/Library writable");
};


package main;
use Test::Builder::Tester tests => 2;

test_out("ok 1 # skip darwin only test");
test_out("ok 2 # skip darwin only test");
Foo->runtests;
test_test("early return handled (skip)");

test_out("not ok 1 - (Bar::darwin_only returned before plan complete)");
test_out("not ok 2 - (Bar::darwin_only returned before plan complete)");
test_err(qr/.*in Bar->darwin_only.*/s);
Bar->runtests;
test_test("early return handled (fail)");

