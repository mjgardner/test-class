#! /usr/bin/perl

use strict;
use warnings;


package Carpet;
use base qw(Class::InsideOut);	# base class that does the work
use Class::InsideOut::Accessor;	# filter that generates accessors

sub new {bless [], shift};

{
	# declare object attributes - lexically scoped to the block
	# not the class!
	my (%width, %height) : Field;	
	
	sub area {
		my $self = shift->self_id; # get the hash key for $self 		
		$width{$self} * $height{$self};
	};
}

{	
	my %unit_price : Field;	
	
	sub price {
		my $self = shift;
		$self->area * $unit_price{$self->self_id};
	};
};

# note, we are forced to use methods since the hashes are scoped
# to the blocks enclosing the methods - now *that's* private :-)
sub display {
	my $self = shift;	
	my ($width, $height, $area, $unit_price, $price) = ($self->width, 
		$self->height, $self->area, $self->unit_price, $self->price);
	print "$width x $height ($area sq m) @ \$$unit_price = \$$price\n";
};

# note lack of DESTROY method - all done automagically


package main;

my $o = Carpet->new;
$o->width(10);
$o->height(10);
$o->unit_price(1.00);
$o->display;
