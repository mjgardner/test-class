#! /usr/bin/perl 

use Test::More tests => 3;
use strict;
use warnings;

{ 
    package Foo;
    use base qw(Class::InsideOut);

    sub new { bless {}, shift };

    my %foo :Field;

    sub foo {
        my $self = shift->self_id;
        @_ ? $foo{$self} = shift : $foo{$self};
    };  
    
    sub Num_objects { scalar(keys(%foo)) };
    
    package Bar;
    use base qw(Class::InsideOut);
};

{
    my $o1 = Foo->new;
    $o1->foo(1);
    {
        my $o2 = Foo->new;
        $o2->foo(2);
        bless $o2, 'Bar';
        is( Foo->Num_objects, 2, '2 objects' );
    };
    is( Foo->Num_objects, 1, '1 object' );
};
is( Foo->Num_objects, 0, '0 objects' );
