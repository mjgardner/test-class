package Discuss::Base;
use base qw(Discuss::DBIObject);

use Discuss::Base::Iterator;
use strict;
use warnings;
use Discuss::Carp;
use List::Util qw(first);
use HTML::Entities;

our $VERSION = '0.09';

sub iterator_class { 'Discuss::Base::Iterator' };

our $Escape_html = 0;

sub is_html { [] };

sub AUTOLOAD {
	my $self = shift;
	our $AUTOLOAD;
	my ($method) = ($AUTOLOAD =~ m/::([^:]+)$/);
	return if $method eq "DESTROY";
	my $columns = $self->columns;
	confess "no method $method for $self (@$columns)"
			unless first {$_ eq $method} @$columns;
	{
		no strict 'refs';
		*{$method} = sub { 
			my $self = shift;
			$self->load if $self->is_lazy and !defined $$self->{$method};
			my $value = $$self->{$method};
			$value = encode_entities($value) 
				if $Escape_html 
				&& not(first {$_ eq $method} @{$self->is_html});
			return $value;
		};
	}
	$self->$method;
};

1;