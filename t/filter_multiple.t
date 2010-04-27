#! /usr/bin/perl

use strict;
use warnings;

package Foo;
use Test::More;
use base qw(Test::Class);

sub test_not_filtered : Test(1) {
    pass( "test_not_filtered doesn't meet any filters, so is run" );
};

sub test_filter_me : Test(1) {
    fail( "shouldn't run, due to filtering of /filter_me/" );
}

sub test_me_too : Test(1) {
    fail( "shouldn't run, due to filtering of /me_too/" );
}

sub test_filter_me_as_well : Test(1) {
    fail( "shouldn't run, due to filtering of /filter_me/" );
}

sub test_another_not_matching : Test(1) {
    pass( "test_another_not_matching doesn't meet any filters, so is run" );
}

package main;

Test::Class->add_filter( sub { $_[1] !~ /filter_me/ } );
Test::Class->add_filter( sub { $_[1] !~ /me_too/ } );

Test::Class->runtests;
