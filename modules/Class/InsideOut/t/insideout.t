#! /usr/bin/perl

use Test::More tests => 15;
use Test::Exception;
use strict;
use warnings;

{ 
	package Foo;
	use base qw(Class::InsideOut);

	my %foo :Field;	

	sub new {
		my $class = shift;
		return(bless {}, $class);
	};
	
	sub foo {
		my $self = shift->self_id;
		@_ ? $foo{$self} = shift : $foo{$self};
	};
	
	{
		my %foo :Field;	
		sub foo2 {
			my $self = shift->self_id;
			@_ ? $foo{$self} = shift : $foo{$self};
		};
		
		sub foo2_used { scalar(keys %foo) };
		
	};
	
	sub foo_used { scalar(keys %foo) };
		
};

{ 
	package SubFoo;
	use base qw(Foo);
	
	my %foo :Field;	# just accessible in SubFoo
	
	sub foo3 {
		my $self = shift->self_id;
		@_ ? $foo{$self} = shift : $foo{$self};
	};
	
	sub foo3_used { scalar(keys %foo) };
	
};

{
	package SubFoo::Pretty;	
	use base qw(SubFoo);
	use warnings;
	use strict;
	
	use overload q{""}	=>	sub {
		my $self = shift;
		"<"
		. join(", ", map { defined $_ ? $_ : 'undef'} 
			($self->foo, $self->foo2, $self->foo3))
		. ">";
	};
};

{
	sub set_foos {
		my $o = shift;
		$o->foo(shift);
		$o->foo2(shift);
		$o->foo3(shift);
	};

	my $o1 = SubFoo->new;
	my $o2 = SubFoo::Pretty->new;
	isa_ok($o1, 'SubFoo');
	isa_ok($o2, 'SubFoo::Pretty');
	
	set_foos($o1,	qw(a b c));
	set_foos($o2,	qw(x y z));

	# to make sure we're not indexing on the class
	bless $o1, 'SubFoo::Pretty';
	bless $o2, 'SubFoo';

	is( $o1->foo,	"a", 'o1 foo  set/get worked' );
	is( $o1->foo2,	"b", 'o1 foo2 set/get worked' );
	is( $o1->foo3,	"c", 'o1 foo3 set/get worked' );
	is( $o2->foo,	"x", 'o2 foo  set/get worked' );
	is( $o2->foo2,	"y", 'o2 foo2 set/get worked' );
	is( $o2->foo3,	"z", 'o2 foo3 set/get worked' );

	is( "$o1", "<a, b, c>", 'overloading works');

	is(SubFoo::Pretty->foo_used, 2, '2 foo slot used');
	is(SubFoo::Pretty->foo2_used, 2, '2 foo2 slot used');
	is(SubFoo::Pretty->foo3_used, 2, '2 foo3 slot used');
	
};

is(SubFoo::Pretty->foo_used, 0, 'destroy worked for foo');
is(SubFoo::Pretty->foo2_used, 0, 'destroy worked for foo2');
is(SubFoo::Pretty->foo3_used, 0, 'destroy worked for foo3');
