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
use Test::More;
$ENV{TEST_VERBOSE}=0;

my $filename = sub { return (caller)[1] }->();

my $test_more_version = eval($Test::More::VERSION);
diag "Test::More: $test_more_version";

test_out( "not ok 1 - object live # TODO unimplemented" );
if ($test_more_version >= 0.9501) {
    # Test-Simple-0.95_01 or later output TODO message to output handle.
    # see http://cpansearch.perl.org/src/MSCHWERN/Test-Simple-0.95_01/Changes
    #    Test::Builder::Tester now sets $tb->todo_output to the output handle and
    #    not the error handle (to be in accordance with the default behaviour of
    #    Test::Builder and allow for testing TODO test behaviour).
    test_out( "#     Failed (TODO) test ($filename at line 16)" );
    test_out( "#   (in Foo->todo_test)" );
} else {
    test_err( "#     Failed (TODO) test ($filename at line 16)" );
    test_err( "#   (in Foo->todo_test)" );
}
Foo->runtests;
test_test("todo tests work");

package Foo;
is( Foo->num_method_tests('todo_test'), 1, 'todo_test should run 1 test' );
