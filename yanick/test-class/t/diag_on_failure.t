#! /usr/bin/perl -T

use strict;
use warnings;
use Test::More tests => 1;
use Test::Builder::Tester;
$|=1;

{   package MyTestClass;
    use base qw( Test::Class );
    use Test::More;
    
    sub passing_test : Test { pass }
    
    sub failing_test : Test { fail }
}

$ENV{TEST_VERBOSE}=0;
test_out( "not ok 1 - failing test" );
test_fail( -5 );
test_err( "#   (in MyTestClass->failing_test)" );
test_out( "ok 2 - passing test" );
Test::Class->runtests;
test_test( "we show the test class and method name on test failure" );

