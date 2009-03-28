#! /usr/bin/perl

use strict;
use warnings;
use Path::Class qw( dir file );

use lib dir( file($0)->parent->parent, 'lib' )->stringify;
use lib dir( file($0)->parent->parent->parent, 'test-more', 'lib' )->stringify;

use Test::Class '0.32_2';

$ENV{ TEST_VERBOSE } = 1;

{   package SimplePassAndFail;
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

{   package SetupAndTeardownWithoutTests;
    use base qw( Test::Class );
    use Test::More;
    
    sub setup :Test( setup ) {
        diag "in setup";
    }
    
    sub teardown :Test( teardown ) {
        diag "in teardown";
    }
    
    sub this_should_pass :Test {
        pass "alpha";
    }
    
    sub this_should_fail :Test {
        fail "beta";
    }
    
}

{   package SetupAndTeardownWithTests;
    use base qw( Test::Class );
    use Test::More;
    
    sub setup :Test( setup => 1 ) {
        pass "in setup";
    }
    
    sub teardown :Test( teardown => 1 ) {
        pass "in teardown";
    }
    
    sub this_should_pass :Test {
        pass "alpha";
    }
    
    sub this_should_fail :Test {
        fail "beta";
    }
    
}

Test::Class->runtests;
print "done\n";