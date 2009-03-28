#! /usr/bin/perl

use strict;
use warnings;
use Path::Class qw( dir file );

use lib dir( file($0)->parent->parent, 'lib' )->stringify;
use lib dir( file($0)->parent->parent->parent, 'test-more', 'lib' )->stringify;

use Test::Class '0.32_2';

{   package NestingTest;
    use base qw( Test::Class );
    use Test::More;
    
    sub this_should_pass :Tests(3) {
        pass "alpha";
        pass "beta";
        pass "gamma";
    }
    
    sub this_should_fail :Tests(3) {
        pass "a";
        fail "b";
        pass "c";
    }
    
}

Test::Class->runtests;
print "done\n";