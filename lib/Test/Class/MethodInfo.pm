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
    my ($class, %param) = @_;
	my $self = bless {
	    name => $param{name},
	    type => $param{type} || 'test',
	}, $class;
	unless ( defined( $param{num_tests} ) ) {
    	$param{num_tests} = $self->is_type('test') ? 1 : 0;
    };
	$self->num_tests( $param{num_tests} );
	return($self);
};

sub name { shift->{name} };

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
    $self->{type} eq $type;
};


1;
