#! /usr/bin/perl -T

use strict;
use warnings;
use Test::Class;
use Test;
use Fcntl;
use IO::File;
use Test::Builder;

{
    package Base::Test;
    use base qw(Test::Class);
    use Test::More;

    sub startup :Test(startup => 1) {
        pass "startup run"
    }

    sub setup :Test(setup => 1) {
        pass "setup run"
    }
    
    sub teardown :Test(teardown => 1) {
        pass "teardown run"
    }
    
    sub shutdown :Test(shutdown => 1) {
        pass "shutdown run"
    }
}

{
    package Bar::Test;
    use base qw(Base::Test);
    use Test::More;

    sub the_test :Test  {
        pass "the_test has been run";
    }
}

# plan tests => 3;
# 
# my $io = IO::File->new_tmpfile or die "couldn't create tmp file ($!)\n";
# my $Test = Test::Builder->new;              
# $Test->output($io);
# $Test->failure_output($io);
# 
# $ENV{TEST_VERBOSE}=0;

$ENV{TEST_VERBOSE}=1;
Test::Class->runtests;
# 
# END {
#     seek $io, SEEK_SET, 0;
#     while (my $actual = <$io>) {
#         chomp($actual);
#         my $expected=<DATA>; chomp($expected);
#         ok($actual, $expected);
#     };
# 
#     ok($?, 0, "exit value okay");
#     $?=0;
# };
# 
# __DATA__
# 1..1
# ok 1 # skip because SKIP_CLASS returned a string
