#! /usr/bin/perl -w

use strict;
use warnings;


package Object;

sub new { return bless {}, shift };


package AnotherObject;

sub make { 
	my $class = shift;
	return bless {@_}, $class;
};


package Object::Test;
use base qw(Test::Class::BaseTest);
use Test::More;

sub check_fixture : Test {
	isa_ok(shift->{object}, 'Object', 'Object::Test fixture');
};


package Another::Test;
use base qw(Test::Class::BaseTest);
use Test::More;

sub create_class { 'AnotherObject' };
sub create_method { 'make' };
sub create_args { (foo => 1) };

sub check_fixture : Test(2) {
	my $object = shift->{object};
	isa_ok($object, 'AnotherObject', 'Another::Test fixture');
	is($object->{foo}, 1, 'creation args overridden');
};


package YetAnother::Test;
use base qw(Test::Class::BaseTest);
use Test::More;

sub check_fixture : Test(2) {
	my $object = shift->{object};
	isa_ok($object, 'AnotherObject', 'YetAnother::Test fixture');
	is($object->{foo}, 1, 'creation args from new');
};


package main;
use Test::More;

my $to = YetAnother::Test->new(
	class => 'AnotherObject',
	method => 'make',
	args => [foo => 1],
);

Test::Class->runtests(qw(Object::Test Another::Test), $to);

