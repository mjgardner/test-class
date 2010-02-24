#! /usr/bin/perl

use strict;
use warnings;
use Test::More tests => 4;
use Test::Exception;
use Test::Builder::Tester;

{   package MyTestClass;
    use base qw(Test::Class);
    use Test::More;    
    sub startup  : Test( startup  => 1 ) { pass "startup" }
    sub shutdown : Test( shutdown => 1 ) { pass "shutdown" }
    sub setup    : Test( setup    => 1 ) { pass "setup" }
    sub teardown : Test( teardown => 1 ) { pass "teardown" }
    sub test1    : Test                  { pass "test1" }
    sub test2    : Test                  { pass "test2" }
    sub test3    : Test                  { pass "test3" }
}

$ENV{ TEST_VERBOSE } = 0;

$ENV{ TEST_METHOD } = '+++';
throws_ok { MyTestClass->runtests } 
    qr/\A\QTEST_METHOD (+++) is not a valid regexp/,
    '$ENV{TEST_METHOD} with an invalid regex should die';

delete $ENV{ TEST_METHOD };
expecting_tests( qw( startup setup test1 teardown setup test2 teardown setup test3 teardown shutdown ) );
test_test( "no TEST_METHOD runs all tests" );

$ENV{ TEST_METHOD } = 'test1';
expecting_tests( qw( startup setup test1 teardown shutdown ) );
test_test( "single match just runs one test" );

$ENV{ TEST_METHOD } = 'test[13]';
expecting_tests( qw( startup setup test1 teardown setup test3 teardown shutdown ) );
test_test( "two matches run both tests" );

####

sub expecting_tests {
    my @test_descriptions = @_;
    my $n = 1;
    foreach my $description ( @test_descriptions ) {
        test_out( "ok " . $n++ . " - $description" );
    }
    MyTestClass->runtests;
}
