#! /usr/bin/perl -T

use strict;
use warnings;

package Foo;
use base qw(Test::Class);
use Test::More;


sub initialise1 :Test(setup) {
	my $self = shift;
	++$self->{initialise1};
};

sub initialise2 :Test(setup => 1) {
	my $self = shift;
	++$self->{initialise2};
	is($self->{initialise1}, $self->{initialise2}, "initialise2: methods ran in order");
};

sub test1 :Test(4) {
	my $self = shift;
	$self->{test}++;
	is($self->{initialise1}, 1, 'test1: initialise1 ran once');
	is($self->{initialise2}, 1, 'test1: initialise2 ran once');
	is($self->{test}, 1, 'test1: first test running');
	is($self->{teardown1}, undef, 'test1: teardown not run');
};


sub test2 : Test {
	fail("this failing tests should be overridden");
};


sub teardown1 :Test(teardown => 1) {
	my $self = shift;
	my $m = $self->current_method;
	is($self->{test}, $self->{initialise1}, "teardown1: setup run for every test");
};

package Bar;
use base qw(Foo);
use Test::More;


sub test2 :Test(4) {
	my $self = shift;
	$self->{test}++;
	is($self->{initialise1}, 2, 'test2: initialise1 ran twice');
	is($self->{initialise2}, 2, 'test2: initialise2 ran twice');
	is($self->{test}, 2, 'test2: second test running');
	is($self->{teardown1}, 1, 'test2: teardown ran once');
};

sub teardown1 :Test(teardown => +3) {
	my $self = shift;
	my $m = $self->current_method;
	++$self->{teardown1};
	is($self->{test}, $self->{teardown1}, "teardown1: teardown run for every test");
	is($self->{initialise1}, $self->{teardown1}, "teardown1: teardown run for every initialise1");
	is($self->{initialise2}, $self->{teardown1}, "teardown1: teardown run for every initialise2");
	$self->SUPER::teardown1;
};

package main;
use Test::More tests => 18;

Bar->new->runtests;
