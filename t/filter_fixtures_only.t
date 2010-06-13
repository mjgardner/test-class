#! /usr/bin/perl

use strict;
use warnings;

package Foo;

use Test::More;
use base qw(Test::Class);

sub test_filtered_startup : Test( startup => 1 ) {
    pass( "startup test is run, even though all tests match filter" );
}

sub test_filtered_setup : Test( setup => 1 ) {
    fail( "setup test not run, as no normal tests are unfiltered" );
}

sub test_filtered_teardown : Test( teardown => 1 ) {
    fail( "teardown test not run, as no normal tests are unfiltered" );
}

sub test_filtered_shutdown : Test( shutdown => 1 ) {
    pass( "shutdown test is run, even though all tests match filter" );
}

sub test_filtered : Test( 1 ) {
    fail( "shouldn't run, due to matching filter" );
}

package main;

Test::Class->add_filter( sub { 0 } );

Test::Class->runtests;
