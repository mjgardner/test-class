use strict;
use warnings;

package Test::Class::MethodInfo;
use Carp;

our $VERSION = '0.52';

sub new {
    my ( $class, %param ) = @_;
	my $self = bless {
	    name => $param{ name },
	    type => $param{ type } || 'test',
	}, $class;
	unless ( defined $param{num_tests} ) {
    	$param{ num_tests } = $self->is_type('test') ? 1 : 0;
    };
	$self->num_tests( $param{num_tests} );
	return $self;
};

sub name { shift->{name} };

sub type { shift->{type} };

sub num_tests	{
	my ( $self, $n ) = @_;
	if ( defined $n ) {
		croak "$n not valid number of tests"
		    unless $self->is_num_tests($n);
		$self->{ num_tests } = $n;
	};
	return $self->{ num_tests };
};

sub is_type {
	my ( $self, $type ) = @_;
    return $self->{ type } eq $type;
};

sub is_method_type {
	my ( $self, $type ) = @_;
	return $type =~ m/^(startup|setup|test|teardown|shutdown)$/s;
};

sub is_num_tests {
	my ( $self, $num_tests ) = @_;
	return $num_tests =~ m/^(no_plan)|(\+?\d+)$/s;
};

1;
__END__

=head1 NAME

Test::Class::MethodInfo - the info associated with a test method

=head1 VERSION

version 0.51

=head1 SYNOPSIS

  # Secret internal class
  # not for public use

=head1 DESCRIPTION

Holds info related to particular test methods. Not part of the public API and likely to change or completely disappear. If you need to rely on any of this code let me know and we'll see if we can work something out.

=head1 METHODS

=over 4

=item B<new>

=item B<is_method_type>

=item B<is_num_tests>

=item B<is_type>

=item B<name>

=item B<type>

=item B<num_tests>

=back

=head1 AUTHOR

Adrian Howard <adrianh@quietstars.com>

If you can spare the time, please drop me a line if you find this module useful.

=head1 SEE ALSO

=over 4

=item L<Test::Class>

What you should be looking at rather than this internal stuff

=back

=head1 LICENCE

Copyright 2006 Adrian Howard, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
