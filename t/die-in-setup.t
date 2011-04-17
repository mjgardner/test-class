#! /usr/bin/perl

use strict;
use warnings;

{
    package Foo;
    use base qw( Test::Class );
    use Test::More;
    
    sub setup_method :Test(setup) {
        die "oops - we died\n";
    }
    
    sub test : Test {
        pass "this should never run";
    }
}

use Test::Builder::Tester tests => 1;
$ENV{TEST_VERBOSE}=0;
test_out( "not ok 1 - setup_method (for test method 'test') died (oops - we died)" );
test_err( "#   Failed test 'setup_method (for test method 'test') died (oops - we died)'" );
test_err( "#   at t/die-in-setup.t line 27." );
test_err( "#   (in Foo->setup_method)" );
test_out("ok 2 # skip setup_method died");
Test::Class->runtests;
test_test("die in setup caused test method to fail");

