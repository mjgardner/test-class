#! /usr/bin/perl -Tw

package Test::Class::MethodInfo;
use 5.006;
use strict;
use warnings;
use Carp;

our $VERSION = '0.01';

=head1 NAME

Test::Class - Base class for mananging test methods.

=head1 SYNOPSIS

Please ignore the man behind the curtain.

=over 4

=cut 

=item B<is_method_type>

Returns true if arg is a method type.

=cut

sub is_method_type { 
	my ($self, $type) = @_;
	return($type =~ m/^(startup|setup|test|teardown|shutdown)$/s);
};


=item B<is_num_tests>

Returns true if arg is a # of tests.

=cut

sub is_num_tests { 
	my ($self, $num_tests) = @_;
	return($num_tests =~ m/^(no_plan)|(\+?\d+)$/s);
};

=item B<new>

Create new Test::Class::Base

=cut

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

=item B<name>

Return the name of a method

=cut

sub name 		{ shift->{name} };

=item B<num_tests>

Return the number of tests

=cut

sub num_tests	{ 
	my ($self, $n) = @_;
	if (defined($n)) {
		croak "$n not valid number of tests" 
				unless $self->is_num_tests($n);
		$self->{_num_tests} = $n;
	};
	return($self->{_num_tests});
};

=item B<is_type>

Is a method of the specified type.

=cut

sub is_type {
	my ($self, $type) = @_;
	return( $self->{types}->{$type} );
};

=back

=cut

1;
