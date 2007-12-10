#! /usr/bin/perl 

use strict;
use warnings;

{
    package StartMethodThatDies;
    use base qw(Test::Class);
    use Test::More;

    sub startup_that_dies : Test( startup ) { die "oops!\n" }

    sub my_test_method : Tests {
        fail('should be skipped because of the startup exception');
    }
}

use Test::Builder::Tester tests => 1;

test_out("not ok 1 - startup_that_dies died (oops!)");
test_fail( +2 );
test_err( "#   (in StartMethodThatDies->startup_that_dies)" );
Test::Class->runtests;
test_test("exception in startup method causes all tests to be skipped");
