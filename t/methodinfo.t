#! /usr/bin/perl

use strict;
use warnings;
use Test::More 'no_plan';
use constant CLASS => 'Test::Class::MethodInfo';
BEGIN { use_ok( CLASS) };

{
    isa_ok my $o = CLASS->new(name=> 'foo'), CLASS;
    ok $o->is_type('test'), 'method type is test by default';
    is $o->num_tests, 1, 'test methods default to 1 test';
};

__END__
{
    isa_ok my $o = CLASS->new(name=> 'foo', num_tests => 0), CLASS;
    is $o->num_tests, 0, 'test method can have zero tests';
};

{
    foreach my $type qw(setup teardown startup shutdown) {
        isa_ok my $o = CLASS->new(name=> 'foo', type=> $type), CLASS, $type;
        ok $o->is_type($type), "method type is $type";
        is $o->num_tests, 0, "$type methods default to 0 test";
    };
};