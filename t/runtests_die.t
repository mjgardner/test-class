#! /usr/bin/perl -T

use strict;
use warnings;

package Object;
sub new { undef };

package Foo;
use Test::More;
use base qw(Test::Class);

sub test_object : Test(2) {
	my $object = Object->new;
	isa_ok($object, "Object") or die("could not create object\n");
	is($object->open, "open worked");
};

package main;
use Test::Builder::Tester tests => 1;
$ENV{TEST_VERBOSE}=0;

my $filename = sub { return (caller)[1] }->();
my $identifier = ($Test::More::VERSION < 0.88) ? 'object' : 'thing';

test_out( qr/not ok 1 - (?:The $identifier|undef) isa '?Object'?\n/);
test_err( "#     Failed test ($filename at line 15)");
test_err( $_ ) for $INC{'Test/Stream.pm'}
    ? ( qr/#     (?:The $identifier|undef) isn't defined\n/, "#   (in Foo->test_object)")
    : ( "#   (in Foo->test_object)", qr/#     (?:The $identifier|undef) isn't defined\n/);
test_out( "not ok 2 - test_object died (could not create object)");
test_err( $_ ) for $INC{'Test/Stream.pm'}
    ? ("#     Failed test ($filename at line 35)", "#   (in Foo->test_object)")
    : ("#   (in Foo->test_object)", "#     Failed test ($filename at line 35)");
Foo->runtests;
test_test("early die handled");
