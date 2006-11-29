#! /usr/bin/perl

use strict;
use warnings;

package Foo;
use base qw(Test::Class);
use Test::More;

sub initialise1 : Test(setup) {
    my $self = shift;
    ++$self->{initialise1};
}

sub initialise2 : Test( setup => 1 ) {
    my $self = shift;
    ++$self->{initialise2};
    is( $self->{initialise1}, $self->{initialise2},
        "initialise2: methods ran in order"
    );
}

sub test1 : Test(4) {
    my $self = shift;
    $self->{test}++;
    is( $self->{initialise1}, $ENV{TEST_COUNT},
        'test1: initialise1 ran once' );
    is( $self->{initialise2}, $ENV{TEST_COUNT},
        'test1: initialise2 ran once' );
    is( $self->{test}, $ENV{TEST_COUNT}, 'test1: first test running' );
    is( $self->{teardown1}, undef, 'test1: teardown not run' );
}

sub customer1 : Test(1) {
    my $self = shift;
    $self->{test}++;
    ok( 1, 'Customer1 was run' );
}

sub customer2 : Test(1) {
    my $self = shift;
    $self->{test}++;
    ok( 1, 'Customer2 was run' );
}

sub teardown1 : Test( teardown => 1 ) {
    my $self = shift;
    my $m    = $self->current_method;
    is( $self->{test}, $self->{initialise1},
        "teardown1: setup run for every test"
    );
}

package main;

use Test::More tests => 16;

$ENV{TEST_COUNT} = 3;
Foo->new->runtests;

$ENV{TEST_METHOD} = '+++';
eval { Foo->new->runtests };
like $@, qr/\A\QTEST_METHOD (+++) is not a valid regular expression/,
  '$ENV{TEST_METHOD} with an invalid regex should die';

$ENV{TEST_METHOD} = 'customer1';
$ENV{TEST_COUNT} = 1;
Foo->new->runtests;

$ENV{TEST_METHOD} = 'customer.*';
$ENV{TEST_COUNT} = 2;
Foo->new->runtests;
