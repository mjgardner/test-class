#! /usr/bin/perl -w

# Example from Test::Class pod

use strict;


package Pig;
sub new { return bless {}, shift };
sub age { 3 };


package NamedPig;
use base qw(Pig);
sub name {'Porky'};


package Pig::Test;
use base qw(Test::Class);
use Test::More;

sub testing_class { "Pig" };
sub new_args { (-age => 3) };

sub setup : Test(setup) {
	my $self = shift;
	my $class = $self->testing_class;
	my @args = $self->new_args;
	$self->{pig} = $class->new( @args );
};

sub _creation : Test {
	my $self = shift;
	isa_ok($self->{pig}, $self->testing_class) 
			or $self->FAIL_ALL('Pig->new failed');
};

sub check_fields : Test {
	my $pig = shift->{pig};
	is($pig->age, 3, "age accessed");
};


package NamedPig::Test;
use base qw(Pig::Test);
use Test::More;

sub testing_class { "NamedPig" };
sub new_args { (shift->SUPER::new_args, -name => 'Porky') };

sub check_fields : Test(+1) {
	my $self = shift;
	$self->SUPER::check_fields;
	is($self->{pig}->name, 'Porky', 'name accessed');
};

package main;

Test::Class->runtests(qw( Pig::Test NamedPig::Test ));
