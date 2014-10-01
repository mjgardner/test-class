#! /usr/bin/perl -T

use strict;
use warnings;

package Local::Test;
use base qw(Test::Class);
use Test::More;

sub test1 : Test { pass() };
sub test2 : Test { fail() };
sub test3 : Test { pass() };
sub test4 : Test { fail() };

package main;
use Test::Builder::Tester tests => 1;

my $filename = sub { return (caller)[1] }->();

$ENV{TEST_VERBOSE} = 1;
test_diag("");
test_diag("Local::Test->test1");
test_out("ok 1 - test1");
test_diag("");
test_diag("Local::Test->test2");
test_out("not ok 2 - test2");
test_diag("  Failed test 'test2'");
test_diag("  at $filename line 11.");
test_diag("  (in Local::Test->test2)");
test_diag("");
test_diag("Local::Test->test3");
test_out("ok 3 - test3");
test_diag("");
test_diag("Local::Test->test4");
test_out("not ok 4 - test4");
test_diag("  Failed test 'test4'");
test_diag("  at $filename line 13.");
test_diag("  (in Local::Test->test4)");
test_diag("Test failures were as follows:");
test_diag("  Local::Test:");
test_diag("    ->test2");
test_diag("    ->test4");
Local::Test->runtests;
test_test("TEST_VERBOSE outputs method diagnostic and summary of failures");
