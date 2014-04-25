#! /usr/bin/perl -T

use strict;
use warnings;

package Foo;
use Test::More;
use base qw(Test::Class);

sub die_one_cr : Test(1) {
        die "\n";
        fail 'we should never get here';
}

sub die_two_cr : Test(1) {
        die "\n\n";
        fail 'we should never get here';
}

package main;
use Test::Builder::Tester tests => 1;
$ENV{TEST_VERBOSE}=0;

my $filename = sub { return (caller)[1] }->();

test_out( "not ok 1 - die_one_cr died ()");
test_err( "#   Failed test 'die_one_cr died ()'" );
test_err( "#   at $filename line 36.");
test_err( "#   (in Foo->die_one_cr)" );
test_out( "not ok 2 - die_two_cr died (");
test_out( "# )");
test_err( "#   Failed test 'die_two_cr died (" );
test_err( "# )'");
test_err( "#   at $filename line 36.");
test_err( "#   (in Foo->die_two_cr)" );
Foo->runtests;
test_test("early die with nearly-empty messages handled");
