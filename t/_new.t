#! /usr/bin/perl -T

use strict;
use warnings;
use Test::Builder;
use Test::More tests => 6;

BEGIN {
	use_ok('Test::Class')  || Test::Builder->BAILOUT("CANNOT USE Test::Class");
};

package Foo;
use base qw(Test::Class);

package main;

my $tc = Foo->new(foo => 42, bar=>3);
isa_ok($tc, "Test::Class") || Test::Builder->BAILOUT("CANNOT CREATE Test::Class OBJECTS");
is($tc->{foo}, 42, 'key/value set');

my $tc2 = $tc->new(bar => 12);
isa_ok($tc2, "Test::Class");
is($tc2->{foo}, 42, 'prototype key/value set');
is($tc2->{bar}, 12, 'new key/value set');
