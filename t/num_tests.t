#! /usr/bin/perl -T

use strict;
use warnings;

package Foo;
use Test::More;
use base qw(Test::Class);

sub test_num_tests : Test(no_plan) {
	my $self = shift;
	is($self->num_tests, 'no_plan', "num_tests access okay");
	$self->num_tests(2);
	is($self->num_tests, 2, "num_tests set okay");
};


package main;
use Test::More tests => 4;

Foo->new->runtests;
Foo->new->runtests;
