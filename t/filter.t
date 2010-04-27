#! /usr/bin/perl

use strict;
use warnings;

package Foo;
use Test::More;
use base qw(Test::Class);

sub test_run : Test(1) {
	pass( "test_run not filtered, so is run" );
};

package Bar;
use Test::More;
use base qw(Test::Class);

sub test_filter_due_to_class : Test(1) {
    fail( "shouldn't run, due to class filter" );
}

package main;

Test::Class->add_filter( sub { $_[0] eq 'Foo' } );

Test::Class->runtests;
