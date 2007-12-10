#! /usr/bin/perl -T

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
use Test::Builder::Tester tests => 2;
$ENV{TEST_VERBOSE}=0;

my $filename = sub { return (caller)[1] }->();

test_out( "not ok 1 - object live # TODO unimplemented" );
test_err( "#     Failed (TODO) test ($filename at line 16)" );

test_err( "#   (in Foo->todo_test)" );
Foo->runtests;
test_test("todo tests work");

package Foo;
is( Foo->num_method_tests('todo_test'), 1, 'todo_test should run 1 test' );
