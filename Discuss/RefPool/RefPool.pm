package Discuss::RefPool;
use strict;
use warnings;
use Discuss::Carp;

our $VERSION = '0.06';

my $Pool={};
my $Count={};

sub pool_key { die "must override pool_key for ", shift, "\n" };

sub pool_shared {
	my $self = shift;
	my $key = $self->pool_key;
	confess "$self->pool_key is undef" unless defined($key);
	my $class = ref($self);
	$Count->{$class}->{$key} - 1;
};

sub pool_size {
	my $class = shift;
	scalar keys %{$Pool->{$class}};		
};

sub pooled_objects {
	my $class = shift;
	map { $class->pool_get($_) } keys %{$Pool->{$class}};	
};

sub pool_get {
	my ($class, $key) = @_;
	confess "key is undef" unless defined($key);
	return unless my $ref = $Pool->{$class}->{$key};
	my $self = bless \$ref, $class;
	$Count->{$class}->{$key}++;
	confess "$self found under wrong key" unless $key eq $self->pool_key;
	return $self;
};

sub pool_set {
	my ($class, $ref) = @_;
	my $self = bless \$ref, $class;
	my $key = $self->pool_key;
	confess "$self->pool_key is undef" unless defined($key);
	$Pool->{$class}->{$key} = $ref;
	$Count->{$class}->{$key}++;
	return($self);
};

sub DESTROY {
	my $self = shift;
	my $class = ref($self);
	my $key = $self->pool_key;
	my $count = --$Count->{$class}->{$key};
	if ($count <= 0) {
		delete $Pool->{$class}->{$key};
		delete $Count->{$class}->{$key};
		die "panic: negative pool count for $self" if $count < 0;
	};
};

1;