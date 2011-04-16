#! /usr/bin/perl -T

use strict;
use warnings FATAL => 'all';
use Test::More;

my $shutdown_has_run;

{   package My::Test;
    use base qw( Test::Class );
    use Test::More;
    
    sub shutdown :Test( shutdown ) {
        $shutdown_has_run = 1;
    }
    
    sub test : Test {
        pass "passing test to force shutdown method to run";
    } 
    
}

My::Test->runtests( +1 );
ok $shutdown_has_run, "shutdown method has run";
