#! /usr/bin/perl -Tw

package Test::Class::MethodInfo;
use 5.006;
use strict;
use warnings;
use Carp;

our $VERSION = '0.01';

sub is_method_type { 
	my ($self, $type) = @_;
	return($type =~ m/^(startup|setup|test|teardown|shutdown)$/s);
};

sub is_num_tests { 
	my ($self, $num_tests) = @_;
	return($num_tests =~ m/^(no_plan)|(\+?\d+)$/s);
};

sub new {
	my $class = shift;
	my %param = @_;
	my $self = bless {}, $class;
	my ($name, $types, $num_tests) = map {
		croak "need to set $_" unless exists $param{$_};
		$param{$_};
	} qw(name type num_tests);
	foreach my $type (@$types) {
		$self->{types}->{$type} = 1;
	};
	$self->num_tests($num_tests);
	$self->{name} = $name;
	return($self);
};

sub name 		{ shift->{name} };

sub num_tests	{ 
	my ($self, $n) = @_;
	if (defined($n)) {
		croak "$n not valid number of tests" 
				unless $self->is_num_tests($n);
		$self->{_num_tests} = $n;
	};
	return($self->{_num_tests});
};

sub is_type {
	my ($self, $type) = @_;
	return( $self->{types}->{$type} );
};


1;
