#! /usr/bin/perl -Tw

use strict;
use warnings;

package Object;
sub live {undef};


package Foo;
use Test::More;
use base qw(Test::Class);

sub todo_test : Test  {
	local $TODO = "unimplemented";
	ok(Object->live, "object live");
};

package main;
use Test::Builder::Tester tests => 1;
$ENV{TEST_VERBOSE}=0;
test_out("not ok 1 - object live # TODO unimplemented");
test_err("#     Failed (TODO) test (t/todo.t at line 16)");
Foo->runtests;
test_test("todo tests work");
