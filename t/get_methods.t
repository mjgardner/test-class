#! /usr/bin/perl -Tw

use strict;


package Foo;
use base qw(Test::Class);

sub test1 : Test {};
sub test3 : Test(+2) {};

sub setup1 : Test(setup) {};
sub setup3 : Test(setup => +2) {};

sub teardown1 : Test(teardown) {};
sub teardown3 : Test(teardown => +2) {};

sub both1 : Test(setup => teardown) {};
sub both3 : Test(setup => teardown => +2) {};


package Bar;
use base qw(Foo);

sub test2 : Test(2) {};
sub test4 : Test(no_plan) {};

sub setup2 : Test(setup => 2) {};
sub setup4 : Test(setup => no_plan) {};

sub teardown2 : Test(teardown => 2) {};
sub teardown4 : Test(teardown => no_plan) {};

sub both2 : Test(setup => teardown => 2) {};
sub both4 : Test(setup => teardown => no_plan) {};


package main;

use Test::More tests => 3;
use Test::Differences;

my @setup = Bar->setup_methods;
my @test = Bar->test_methods;
my @teardown = Bar->teardown_methods;

is_deeply(
	\@setup,
	[qw( both1 both2 both3 both4 setup1 setup2 setup3 setup4)],
	'setup_methods'
);

is_deeply(
	\@test,
	[qw( test1 test2 test3 test4 )],
	'test_methods'
);

is_deeply(
	\@teardown,
	[qw( both1 both2 both3 both4 teardown1 teardown2 teardown3 teardown4)],
	'teardown_methods'
);
