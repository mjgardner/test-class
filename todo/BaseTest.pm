#! /usr/bin/perl -w

package Test::Class::BaseTest;
use base qw(Test::Class);
use strict;
use warnings;
use Carp;
use Test::More;


=head1 NAME

Test::BaseTest - Useful base class for your Test::Class objects

=cut

=over 4

=item B<create_class>

=cut

sub create_class {
	my $self = shift;
	return $self->{class} if exists $self->{class};
	my $class = ref($self);
	croak "expecting ClassToTest::Test, found $class" 
			unless $class =~ m/^(.*)::Test/s;
	return($1);
};


=item B<create_method>

=cut

sub create_method	{ shift->{method} || "new" };


=item B<create_args>

=cut

sub create_args		{ 
	my $args = shift->{args} || [];
	return @$args;
};


=item B<Create_fixture>

=cut

sub Create_fixture : Test(setup) {
	my $self = shift;
	my $method = $self->create_method;
	my @args = $self->create_args;
	my $class = $self->create_class;
	$self->{object} = $class->$method(@args);
};


=item B<Check_fixture>

=cut

sub Check_fixture : Test {
	my $self = shift;
	my $class = $self->create_class;
	isa_ok($self->{object}, $class) 
			|| $self->FAIL_ALL("could not create $class fixture");
};

=back

=cut


1;
