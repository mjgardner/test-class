#! /usr/bin/perl -Tw

use strict;

package Local::Test;
use base qw(Test::Class);
use Test::More;

sub setup : Test(setup) {
	my $self = shift;
	$self->num_method_tests('test', 2);
};

sub test : Test(no_plan) {
	my $self = shift;
	is($self->num_tests, 2, 'test number set');
	is($self->builder->expected_tests, 2, 'builder expected tests set');
};


package main;

Local::Test->runtests();
