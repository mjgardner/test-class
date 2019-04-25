#! /usr/bin/perl -T

use strict;
use warnings;
$ENV{TEST_VERBOSE}=0;

package SkipMissingTests;
use Test::More;
use base qw(Test::Class);

sub darwin_only : Tests(2) {
    return("darwin only test");# unless $^O eq "darwin";
    ok(-w "/Library", "/Library writable");
    ok(-r "/Library", "/Library readable");
}

package FailMissingTests;
use Test::More;
use base qw(Test::Class);

sub fail_if_returned_early { 1 }

sub darwin_only : Tests(2) {
    return("darwin only test");# unless $^O eq "darwin";
    ok(-r "/Library", "/Library readable");
    ok(-w "/Library", "/Library writable");
}

package AllowMoreTests;
use Test::More;
use base qw(Test::Class);

sub more_tests : Tests(1) {
    pass;
    pass;
}

sub other_tests : Tests {
    pass;
}

package DisallowMoreTests;
use Test::More;
use base qw(Test::Class);

sub fail_if_returned_late { 1 }

sub more_tests : Tests(1) {
    pass;
    pass;
}

sub other_tests : Tests {
    pass;
}

package AllowMoreAndLessTests;
use Test::More;
use base qw(Test::Class);

sub more_tests : Tests(1) {
    pass;
    pass;
}

sub less_tests : Tests(2) {
    pass;
}

sub other_tests : Tests {
    pass;
}

package DisallowMoreAndLessTests;
use Test::More;
use base qw(Test::Class);

sub fail_if_returned_early { 1 }
sub fail_if_returned_late { 1 }

sub more_tests : Tests(1) {
    pass;
    pass;
}

sub less_tests : Tests(2) {
    pass;
}

sub other_tests : Tests {
    pass;
}


package main;
use Test::Builder::Tester tests => 6;

test_out("ok 1 # skip darwin only test");
test_out("ok 2 # skip darwin only test");
SkipMissingTests->runtests;
test_test("early return handled (skip)");

test_out("not ok 1 - (FailMissingTests::darwin_only returned before plan complete)");
test_out("not ok 2 - (FailMissingTests::darwin_only returned before plan complete)");
test_err(qr/.* at \Q$0\E line .*in FailMissingTests->darwin_only.*/s);
FailMissingTests->runtests;
test_test("early return handled (fail)");

test_out("ok 1 - more tests");
test_out("ok 2 - more tests");
test_err("# expected 1 test(s) in AllowMoreTests::more_tests, 2 completed");
test_out("ok 3 - other tests");
AllowMoreTests->runtests;
test_test("late return handled (skip)");

test_out("ok 1 - more tests");
test_out("ok 2 - more tests");
test_out("not ok 3 - expected 1 test(s) in DisallowMoreTests::more_tests, 2 completed");
test_err(qr/.* at \Q$0\E line .*in DisallowMoreTests->more_tests.*/s);
test_out("ok 4 - other tests");
DisallowMoreTests->runtests;
test_test("late return handled (fail)");

test_out("ok 1 - less tests");
test_out("ok 2 # skip 1");
test_out("ok 3 - more tests");
test_out("ok 4 - more tests");
test_err("# expected 1 test(s) in AllowMoreAndLessTests::more_tests, 2 completed");
test_out("ok 5 - other tests");
AllowMoreAndLessTests->runtests;
test_test("early and late return handled (skip)");

test_out("ok 1 - less tests");
test_out("not ok 2 - (DisallowMoreAndLessTests::less_tests returned before plan complete)");
test_out("ok 3 - more tests");
test_out("ok 4 - more tests");
test_out("not ok 5 - expected 1 test(s) in DisallowMoreAndLessTests::more_tests, 2 completed");
test_out("ok 6 - other tests");
test_err(qr/.* at \Q$0\E line .*in DisallowMoreAndLessTests->less_tests.* at \Q$0\E line .*in DisallowMoreAndLessTests->more_tests.*/s);
DisallowMoreAndLessTests->runtests;
test_test("early and late return handled (fail)");
