#! /usr/bin/perl

use strict;
use warnings;
use Test::More tests => 2;

{
    package My::Test;
    use base qw( Test::Class );
    use Test::More;
    
    sub Tests_attribute_default_number_of_tests :Tests {
        my $self = shift;
        is( $self->num_tests, 'no_plan' );
    };
    
    sub Tests_attribute_set_number_of_tests :Tests(1) {
        my $self = shift;
        is( $self->num_tests, 1 );
    };
    
};

My::Test->runtests;

