package Discuss::DBIObject;
use base qw(Discuss::RefPool);

use strict;
use warnings;
use Discuss::Carp;
use Discuss::DBIObject::Iterator;
use Discuss::Exceptions qw(throw_no_such_object);

our $VERSION = '0.12';

sub _check_required_fields {
	my ($class, $param) = @_;
	foreach (@{$class->required}) { 
		confess "no $_" unless $param->{$_}
	};
};

sub _default_fields {
	my $class = shift;
	map {ref($_) eq "CODE" ? $_->() : $_} @{$class->default}
};

sub new {
	my ($class, %param) = @_;
	_check_required_fields($class, \%param);
	my $self = { _default_fields($class), %param };
	my $dbh = $self->{dbh} || confess "no dbh";
	my ($primary, @columns) = @{$class->columns};
	my $table			= $class->table;
	my $columns			= join(',', @columns);
	my $placeholders	= join(',', ('?') x @columns);
	$dbh->prepare_cached(
		"insert into $table ($columns) values ($placeholders)"
	)->execute(map {$self->{$_}} @columns);
	$self->{$primary} = $dbh->{'mysql_insertid'}
		or confess "panic: no insertid!";
	confess "duplicate $class ($primary)"
		if $class->pool_get( $self->{$primary} );
	return( $class->pool_set( $self ) );
};

sub table		{ confess "override table in ", shift, "\n"}
sub columns		{ confess "override columns in ", shift, "\n"}
sub default 	{ confess "override default in ", shift, "\n"}
sub required	{ confess "override required in ", shift, "\n"}

sub primary { shift->columns->[0] };

sub pool_key {
	my $self = shift;
	$$self->{$self->primary};
};

sub iterator_class { 'Discuss::DBIObject::Iterator' };

sub iterator {
	my $class = shift;
	confess "class method" if ref($class);
	$class->iterator_class->new(class => $class, @_);
};

sub is_lazy {
	my $self = shift;
	$$self->{lazy};
};

sub load {
	my $self = shift;
	return $self unless $self->is_lazy;
	my $class = ref($self);
	$class->iterator(dbh => $$self->{dbh})
		->where($self->primary => $self->pool_key)->next
		|| throw_no_such_object class => $class, key => $self->pool_key;
};

sub load_all {
	my $class = shift;
	my $primary = $class->primary;
	my @primaries = map {$_->is_lazy ? $_->pool_key : () } @_;
	return unless @primaries;
	$class->iterator(dbh => ${$_[0]}->{dbh})
		->where_in($primary, @primaries)->as_list;
};

sub fetch {
	my ($class, %param) = @_;
	confess "class method" if ref($class);
	my $primary = $class->primary;
	my $key = $param{$primary};
	throw_no_such_object class => $class, key => $key unless $key;
	$class->pool_get( $key )
		|| $class->iterator(dbh => $param{dbh}, lazy => $param{lazy})
				->where($primary => $key)->next
		|| throw_no_such_object class => $class, key => $key;
};

1;
