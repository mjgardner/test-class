#! /usr/bin/perl

use strict;
use warnings;
use Test::More 'no_plan';
use Scalar::Util qw(refaddr);

{
	package Foo;
	use base qw(Discuss::RefPool);

	sub new {
		my ($class, $n) = @_;
		$class->pool_get($n) || $class->pool_set({n => $n});
	};
	
	sub n {
		my $self = shift;
		$$self->{n};
	};
	
	sub pool_key { shift->n };
};

{
	package FooBar;
	use base qw(Foo);
};

{
	package Bar;
	use base qw(Discuss::RefPool);
	
	sub new {
		my ($class, %param) = @_;
		$class->pool_get( $param{foo} ) || $class->pool_set( \%param );
	};
	
	sub pool_key { ${+shift}->{foo} };
	
};

{
	my $f1 = Foo->new(1);
	isa_ok $f1, 'Foo', 'f1';
	{	
		my $f2 = Foo->new(2);
		isa_ok $f2, 'Foo', 'f2';
		{	
			my $f3 = Foo->new(1);
			isa_ok $f3, 'Foo', 'f3';
			{		
				my $fb1 = FooBar->new(1);
				isa_ok $fb1, 'FooBar', 'fb1';
				{
					my $fb2 = FooBar->new(1);
					isa_ok $fb2, 'FooBar', 'fb2';
					{
						my $b1 = Bar->new(foo => 12, bar => 13);
						isa_ok $b1, 'Bar', 'b1';
						{
							my $b2 = Bar->new(foo => 12, bar => 13);
							isa_ok $b1, 'Bar', 'b2';
							{
								my $b3 = Bar->new(foo => 1, ni => 2);
								isa_ok $b1, 'Bar', 'b3';
							
								is $f1->n, 1, 'f1 set';
								is $f2->n, 2, 'f2 set';
								is $f3->n, 1, 'f3 set';
								is $fb1->n, 1, 'fb1 set';
								is $fb2->n, 1, 'fb2 set';
								is $$b1->{foo}, 12, 'b1 foo set';
								is $$b1->{bar}, 13, 'b1 bar set';
								is $$b2->{foo}, 12, 'b2 foo set';
								is $$b2->{bar}, 13, 'b2 bar set';
								is $$b3->{foo}, 1, 'b3 foo set';
								is $$b3->{ni}, 2, 'b3 ni set';
								
								is refaddr($$f1), refaddr($$f3), 'f1 f3 inner refs identical';
								is refaddr($$fb1), refaddr($$fb2), 'fb1 fb2 inner refs identical';
								isnt refaddr($$f1), refaddr($$fb1), 'f1 fb1 inner refs differ';
								is refaddr($$b1), refaddr($$b2), 'b1 b2 inner refs identical';
								
								{
									my @objects = map {$_->n} Foo->pooled_objects;
									ok( eq_set(\@objects, [$f1->n, $f2->n]), 'pooled_objects' );
								}
							
								is(Foo->pool_size, 2, 'two objects in Foo pool');
								is(FooBar->pool_size, 1, 'one object in FooBar pool');
								is(Bar->pool_size, 2, 'two objects in Bar pool');								
								is($f1->pool_shared, 1, 'f1 shared with one other object');
								is($f2->pool_shared, 0, 'f2 shared with no object');
								is($f3->pool_shared, 1, 'f3 shared with one other object');
								is($fb1->pool_shared, 1, 'fb1 shared with one other object');
								is($fb2->pool_shared, 1, 'fb2 shared with one other object');
								is($b1->pool_shared, 1, 'b1 shared with one other object');
								is($b2->pool_shared, 1, 'b2 shared with one other object');
								is($b3->pool_shared, 0, 'b3 shared with no object');
							};
							is(Foo->pool_size, 2, 'two objects in Foo pool');
							is(FooBar->pool_size, 1, 'one object in FooBar pool');
							is(Bar->pool_size, 1, 'one object in Bar pool');
							is($f1->pool_shared, 1, 'f1 shared with one other object');
							is($f2->pool_shared, 0, 'f2 shared with no object');
							is($f3->pool_shared, 1, 'f3 shared with one other object');
							is($fb1->pool_shared, 1, 'fb1 shared with one other object');
							is($fb2->pool_shared, 1, 'fb2 shared with one other object');
							is($b1->pool_shared, 1, 'b1 shared with one other object');
							is($b2->pool_shared, 1, 'b2 shared with one other object');
						};
						is(Foo->pool_size, 2, 'two objects in Foo pool');
						is(FooBar->pool_size, 1, 'one object in FooBar pool');
						is(Bar->pool_size, 1, 'one object in Bar pool');
						is($f1->pool_shared, 1, 'f1 shared with one other object');
						is($f2->pool_shared, 0, 'f2 shared with no object');
						is($f3->pool_shared, 1, 'f3 shared with one other object');
						is($fb1->pool_shared, 1, 'fb1 shared with one other object');
						is($fb2->pool_shared, 1, 'fb2 shared with one other object');
						is($b1->pool_shared, 0, 'b1 shared with no object');
					};
					is(Foo->pool_size, 2, 'two objects in Foo pool');
					is(FooBar->pool_size, 1, 'one object in FooBar pool');
					is(Bar->pool_size, 0, 'no object in Bar pool');
					is($f1->pool_shared, 1, 'f1 shared with one other object');
					is($f2->pool_shared, 0, 'f2 shared with no object');
					is($f3->pool_shared, 1, 'f3 shared with one other object');
					is($fb1->pool_shared, 1, 'fb1 shared with one other object');
					is($fb2->pool_shared, 1, 'fb2 shared with one other object');
				};
				is(Foo->pool_size, 2, 'two objects in Foo pool');
				is(FooBar->pool_size, 1, 'one object in FooBar pool');
				is(Bar->pool_size, 0, 'no object in Bar pool');
				is($f1->pool_shared, 1, 'f1 shared with one other object');
				is($f2->pool_shared, 0, 'f2 shared with no object');
				is($f3->pool_shared, 1, 'f3 shared with one other object');
				is($fb1->pool_shared, 0, 'fb1 shared with one other object');
			};
			is(Foo->pool_size, 2, 'two objects in Foo pool');
			is(FooBar->pool_size, 0, 'no object in FooBar pool');
			is(Bar->pool_size, 0, 'no object in Bar pool');
			is($f1->pool_shared, 1, 'f1 shared with one other object');
			is($f2->pool_shared, 0, 'f2 shared with no object');
			is($f3->pool_shared, 1, 'f3 shared with one other object');
		};
		is(Foo->pool_size, 2, 'two objects in Foo pool');
		is(FooBar->pool_size, 0, 'no object in FooBar pool');
		is(Bar->pool_size, 0, 'no object in Bar pool');
		is($f1->pool_shared, 0, 'f1 shared with one other object');
		is($f2->pool_shared, 0, 'f2 shared with no object');
	};
	is(Foo->pool_size, 1, 'one object in Foo pool');
	is(FooBar->pool_size, 0, 'no object in FooBar pool');
	is(Bar->pool_size, 0, 'no object in Bar pool');
	is($f1->pool_shared, 0, 'f1 shared with one other object');
};

is(Foo->pool_size, 0, 'no objects in Foo pool');
is(FooBar->pool_size, 0, 'no objects in FooBar pool');
is(Bar->pool_size, 0, 'no objects in Bar pool');

my $f1 = Foo->new(1);
isa_ok $f1, 'Foo', 'f1';
is(Foo->pool_size, 1, 'no objects in Foo pool');
is($f1->pool_shared, 0, 'f1 shared with one other object');
