#! /usr/bin/perl -T

use strict;
use warnings;

package Tests1; use base qw(Test::Class);

sub start : Test(setup => 1) {};
sub test : Test(1) {};
sub end : Test(teardown => 1) {};

package Tests2; use base qw(Test::Class);

sub start : Test(setup => no_plan) {};
sub test : Test(1) {};
sub end : Test(teardown => 1) {};

package Tests3; use base qw(Test::Class);

sub start : Test(setup => 1) {};
sub test : Test(no_plan) {};
sub end : Test(teardown => 1) {};

package Tests4; use base qw(Test::Class);

sub start : Test(setup => 1) {};
sub test : Test(1) {};
sub end : Test(teardown => no_plan) {};


package main;
use Test::More tests => 7;
use Test::Exception;

is(Tests1->expected_tests, 3, 'all set');
is(Tests2->expected_tests, 'no_plan', 'no_plan setup');
is(Tests3->expected_tests, 'no_plan', 'no_plan test');
is(Tests4->expected_tests, 'no_plan', 'no_plan teardown');

my $o1 = Tests1->new;
my $o2 = Tests1->new;
is(Test::Class->expected_tests($o1, $o2, 1), 7, 'expected_test_of');
is(Test::Class->expected_tests($o1, 'Tests3'), 'no_plan', 'no_plan expected_test_of');
dies_ok {Test::Class->expected_tests('foo')} 'bad test class';
