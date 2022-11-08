#!/usr/bin/perl -T

use strict;
use warnings;
use Test::More tests => 1;
use Test::Builder::Tester;

package Destroyer;

sub new { bless {} }

sub DESTROY { $@ = q<> }

package Object::Test;
use base qw(Test::Class);
use Test::More;

sub clobbered_EVAL_ERROR : Test(1) {
   for ( Destroyer->new() ) {
       die 'haha';
   }
}

package main;

test_out(qr/.*died.*/s);
test_err(qr/.*died.*/s);

Object::Test->runtests;

END {
    test_test("report uncaught exception even if it might be clobbered");
}
