use strict;
use warnings;

use Test::More tests => 5;
use Capture::Tiny qw(capture);
plan( skip_all => "This test fails on Perl 5.12 and earlier probably because of lack of subtest support." ) if $] < 5.014;

diag "good_test_count_and_exception";
{
    my ($out, $err, $exit) = capture { system "$^X t/examples/good-test-count-and-exception.pl" };
    is $exit, 256;
    cmp_ok index($out, 'not ok 3 - mytest died'), '>', 0;
    cmp_ok index($out, '123123'), '>', 0;
    cmp_ok index($err, 'mytest died'), '>', 0;
}

diag "bad_test_count_and_exception";
{
    my ($out, $err, $exit) = capture { system "$^X t/examples/bad-test-count-and-exception.pl" };
    #is $exit, 256;
    #cmp_ok index($out, 'not ok 3 - mytest died'), '>', 0;
    #cmp_ok index($out, '123123'), '>', 0;
    #cmp_ok index($err, 'mytest died'), '>', 0;
    ok 1;
}

