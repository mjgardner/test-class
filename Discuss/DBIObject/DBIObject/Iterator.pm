package Discuss::DBIObject::Iterator;
use strict;
use warnings;
use Discuss::Carp;
use base qw(Discuss::DBIObject::SQL);

our $VERSION = '0.16';

sub new {
	my $class = shift;
	my $iterator = $class->SUPER::new(@_);
	my %param = @_;
	my $class_to_create = $param{class} || confess("need class");
	my @select = $param{lazy} ? ($class_to_create->primary)
		: @{$class_to_create->columns};
	$iterator->{_class} = $class_to_create;
	$iterator->{_lazy} = $param{lazy};
	$iterator->from( $class_to_create->table )->select( @select );
	return($iterator);
};

sub class { shift->{_class} };

sub next {
	my $iterator = shift;
	return undef unless my $next = $iterator->SUPER::next();
	my $class = $iterator->{_class};
	my $key = $next->{$class->primary};
	my $object = $class->pool_get($key);
	my $object_exists = $object;
	$object = $class->pool_set( $next ) unless $object_exists;
	@$$object{keys %$next} = values %$next unless $iterator->{_lazy};
	$$object->{dbh} = $iterator->{_dbh};
	$$object->{lazy} = $iterator->{_lazy}
		unless $object_exists && ! $object->is_lazy;
	return($object);
};

1;
