#! /usr/bin/perl -Tw

use Test::More tests => 5;
use strict;
use warnings;

{ 
	package Foo;
	use base qw(Class::InsideOut);

	sub new { bless {}, shift };

	my %foo :Field;			
};

{
	package Bar;
	use base qw(Foo);
	
	my (%bar, %ni) : Field;
};

{
	my $o1 = Bar->new;
	isa_ok($o1, 'Foo');
	
	can_ok('Bar', qw(foo bar ni) );
	$o1->foo(42);
	$o1->bar(24);
	$o1->ni(99);
	
	is( $o1->foo,	42, 'foo' );
	is( $o1->bar,	24, 'bar' );
	is( $o1->ni,	99, 'ni' );
};
