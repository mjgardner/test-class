#! /usr/bin/perl -T

use strict;
use warnings;

package Foo; use base qw(Test::Class);
use Test::More;
use Test::Exception;

sub passN {
	my ($self, $n) = @_;
	my $m = $self->current_method;
	pass("$m just passing $_") foreach (1..$n);
};

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);
	is($self->num_method_tests('two_tests'), 2, 'fixed num tests');
	is($self->num_method_tests('no_plan_test'), 'no_plan', 'no_plan tests');
	throws_ok {$self->num_method_tests('fribble')} qr/not a test method/, 'cannot use non-method';
	throws_ok {$self->num_method_tests('no_plan_test', 'goobah')} qr/not valid number/, 'cannot update illegal value';
	lives_ok {$self->num_method_tests('no_plan_test', 2)} 'updated legal value';
	is($self->num_method_tests('no_plan_test'), 2, 'update worked');
	lives_ok {$self->num_method_tests('no_plan_test2', '+2')} 'updated extended';
	is($self->num_method_tests('no_plan_test2'), '+2', 'update worked');
	return($self);
};

sub two_tests : Test(2) {$_[0]->passN(2)};
sub no_plan_test : Test(no_plan) {$_[0]->passN(2)};
sub no_plan_test2 : Test(no_plan) {$_[0]->passN(2)};

package Bar; use base qw(Foo);
use Test::More;

sub no_plan_test : Test(+1) {pass("just passing"); $_[0]->SUPER::no_plan_test};

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);
	is($self->num_method_tests('no_plan_test'), '+1', 'extended method okay');
	return($self);
};


package main;
use Test::More tests => 19;
use Test::Exception;

my $tc = Bar->new;
is(Bar->expected_tests, 'no_plan', 'class expected_tests');
is($tc->expected_tests, 7, 'object expected_tests');
throws_ok {$tc->num_method_tests('two_tests')} qr/not called in a Test::Class/, 'num_method_tests dies outside test class';
$tc->runtests;
