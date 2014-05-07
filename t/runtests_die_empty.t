#! /usr/bin/perl -T

use strict;
use warnings;

package Object;
use overload
    bool => sub { 1 },  # there is an exception here even if it stringifies as empty!
    '""' => 'as_string',
    fallback => 1;
sub new {
    my ($class, %args) = @_;
    bless { %args }, $class;
}
sub as_string {
    return defined $_[0]->{message}
        ? $_[0]->{message}
        : '';
}

package Foo;
use Test::More;
use base qw(Test::Class);

sub die_empty : Test(1) {
        die Object->new();
        fail 'we should never get here';
}

package main;
use Test::Builder::Tester tests => 1;
$ENV{TEST_VERBOSE}=0;

my $filename = sub { return (caller)[1] }->();

test_out( "not ok 1 - die_empty died ()");
test_err( "#   Failed test 'die_empty died ()'" );
test_err( "#   at $filename line 40.");
test_err( "#   (in Foo->die_empty)" );
Foo->runtests;
test_test("we can handle an exception that stringifies to the empty string");
