#! /usr/bin/perl -Tw

use strict;

package Foo; use base qw(Test::Class);
use Test::More;

sub no_plan_t : Test(no_plan) {};

sub one_test : Test {
	my $self = shift;
	is($self->total_num_tests, 1, 'internal method call');
};


package Bar; use base qw(Foo);
sub one_test : Test(+2) {};


package Ni; use base qw(Bar);
sub one_test : Test(44) {};


package main;
use Test::More tests => 7;
use Test::Exception;

throws_ok {Foo->total_num_tests} qr/method name/, 'no method detected';
throws_ok {Foo->total_num_tests('not_a_test')} qr/not a test/, 'not a test detected';
is(Foo->total_num_tests('no_plan_t'), 'no_plan', 'no_plan detected');
is(Foo->total_num_tests('one_test'), 1, 'one_test');
is(Bar->total_num_tests('one_test'), 3, 'one_test +2');
is(Ni->total_num_tests('one_test'), 44, 'one_test overridden');
Foo->new->runtests;
