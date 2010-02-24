#! /usr/bin/perl -T

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


test_out("not ok 1 - The object isa Object");
test_out("not ok 2 - cannot create Objects");
test_fail(-11);
test_err( "#   (in Object::Test->_test_new)" );
test_err(qr/#\s+The object isn't defined\n/);
test_fail(-14);
test_err( "#   (in Object::Test->_test_new)" );

Object::Test->runtests;
END {
	test_test("fail2");
	is($?, 2, "exit value okay");
	$?=0;
}
