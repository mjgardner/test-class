#! /usr/bin/perl -T

use strict;
use warnings;

my @ORDER = qw (
	start1
	start2
	setup1
	setup2
	test1
	tear1
	tear2
	setup1
	setup2
	test2
	tear1
	tear2
	end1
	end2
);


package Foo::Test;
use base qw(Test::Class);
use Test::More;

sub trace_ok {
	my $caller = (caller(1))[3];
	$caller =~ s/^.*://s;
	my $expected = shift @ORDER;
	is($caller, $expected, "called $expected");
};

sub start1	: Test(startup=>1)	{ trace_ok() };
sub start2	: Test(startup=>1)	{ trace_ok() };

sub setup1	: Test(setup=>1)	{ trace_ok() };
sub setup2	: Test(setup=>1)	{ trace_ok() };

sub test1	: Test(1)			{ trace_ok() };
sub test2	: Test(1)			{ trace_ok() };

sub tear1	: Test(teardown=>1)	{ trace_ok() };
sub tear2	: Test(teardown=>1)	{ trace_ok() };

sub end1	: Test(shutdown=>1)	{ trace_ok() };
sub end2	: Test(shutdown=>1)	{ trace_ok() };


package main;
use Test::More;

Foo::Test->runtests(+1);
ok(@ORDER==0, 'all expected methods ran');
