#! /usr/bin/perl -T

use strict;
use warnings;

package Tests1;
use base qw(Test::Class);
use Test::More;

sub setup : Test(setup) {
	my $self = shift;
	$self->FAIL_ALL("premature plan") if $self->builder->expected_tests;
};

sub test : Test { pass('Tests1 test') };


package Tests2;
use base qw(Test::Class);
use Test::More;

sub test : Test { pass('Tests2 test') };


package main;
use Test::More;

Test::Class->runtests('Tests1', 'Tests2', +1);
is(Tests1->builder->expected_tests, 3, 'correct number of tests');
