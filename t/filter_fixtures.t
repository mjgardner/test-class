#! /usr/bin/perl

use strict;
use warnings;

package Foo;

use Test::More;
use base qw(Test::Class);

sub test_filtered_startup : Test( startup => 1 ) {
    pass( "startup test is run, even though matches filter" );
}

sub test_filtered_setup : Test( setup => 1 ) {
    pass( "setup test is run, even though matches filter" );
}

sub test_filtered_teardown : Test( teardown => 1 ) {
    pass( "teardown test is run, even though matches filter" );
}

sub test_filtered_shutdown : Test( shutdown => 1 ) {
    pass( "shutdown test is run, even though matches filter" );
}

sub test_filtered : Test( 1 ) {
    fail( "shouldn't run, due to matching filter" );
}

sub test_should_run : Test( 1 ) {
    pass( "should run, due to not matching filter" );
}

package main;

Test::Class->add_filter( sub { $_[1] !~ /filtered/ } );

Test::Class->runtests;
