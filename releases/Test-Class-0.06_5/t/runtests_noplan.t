#! /usr/bin/perl -T

use strict;
use warnings;


package Foo;
use Test::More;

use base qw(Test::Class);

sub set_tests : Test(1) {
	pass("this should pass");
};

sub undef_tests : Test(no_plan) {
	my $self = shift;
	my $n = $self->{runtime_tests};
	foreach $n (1..$n) {
		pass("runtime test $n");
	};
};


package main;
use Test::More;
use Test::Exception;

my $foo = Foo->new;
$foo->{runtime_tests} = 2;

$foo->runtests;

my $expected = $foo->{runtime_tests} + 1;
my $ran = $foo->builder->current_test;
is($ran, $expected, "expected number of tests ran");
