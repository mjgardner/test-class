package Discuss::Base::Iterator;
use base qw(Discuss::DBIObject::Iterator);

use strict;
use warnings;

our $VERSION = '0.04';

sub limit {
	my ($self, $limit) = @_;
	$limit ? $self->SUPER::limit($limit) : $self;
};

sub by_name {
	my ($self, $limit) = @_;
	$self->order_by('name')->order('asc')->limit($limit);
};

sub most_recent {
	my ($self, $limit) = @_;
	$self->order_by($self->class->primary)->order('desc')->limit($limit);
};

sub most_popular {
	my ($self, $limit) = @_;
	$self->order_by('num_posts')->order('desc')->limit($limit);
};

1;