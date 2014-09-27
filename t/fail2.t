#!/usr/bin/perl -T

use strict;
use warnings;
use Test::More tests => 2;
use Test::Builder::Tester;

package Object;
sub new {return(undef)};


package Object::Test;
use base qw(Test::Class);
use Test::More;

sub _test_new : Test(3) {
	my $self = shift;
	isa_ok(Object->new, "Object") 
		|| $self->FAIL_ALL('cannot create Objects');
};


package main;
$ENV{TEST_VERBOSE}=0;

my $identifier = ($Test::More::VERSION < 0.88) ? 'object' : 'thing';

test_out(qr/not ok 1 - (?:The $identifier|undef) isa '?Object'?\n/);
test_out("not ok 2 - cannot create Objects");
test_fail(-12);
test_err( $_ ) for $INC{'Test/Stream.pm'}
    ? (qr/#\s+(?:The $identifier|undef) isn't defined\n/, "#   (in Object::Test->_test_new)")
    : ("#   (in Object::Test->_test_new)", qr/#\s+(?:The $identifier|undef) isn't defined\n/);
test_fail(-16);
test_err( "#   (in Object::Test->_test_new)" );

Object::Test->runtests;
END {
	test_test("fail2");
	is($?, 2, "exit value okay");
	$? = 0;
}
