#! /usr/bin/perl -Tw

use strict;

package Local::Test;
use base qw(Test::Class);
use Test::More;

sub test1 : Test { ok(1) };
sub test2 : Test { ok(1) };

package main;
use Test::Builder::Tester tests => 1;

$ENV{TEST_VERBOSE}=1;
test_diag("Local::Test->test1");
test_out("ok 1");
test_diag("Local::Test->test2");
test_out("ok 2");
Local::Test->runtests;
test_test("TEST_VERBOSE outputs method diagnostic");
