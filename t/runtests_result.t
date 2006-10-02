#! /usr/bin/perl -T

use strict;
use warnings;

package Fail;
use Test::More;
use base qw(Test::Class);

sub test1 : Test(1) {
	fail("fails");
}; 

sub test2 : Test(1) {
	pass("passes");
}; 


package Pass;
use Test::More;
use base qw(Test::Class);

sub test1 : Test(1) {
	pass("a successful test");
}; 


package main;
use Test::Builder::Tester tests => 4;
use Test::More;
$ENV{TEST_VERBOSE}=0;
my $SEP = '/'; # use forward slash even on Win32

my $all_ok;

test_out("not ok 1 - fails");
test_err("#     Failed test (t${SEP}runtests_result.t at line 11)");
test_out("ok 2 - passes");
$all_ok = Fail->runtests;
test_test("single failure ran okay");
is($all_ok, 0, "failure detected");

$all_ok = Pass->runtests;
ok($all_ok, "success detected");
