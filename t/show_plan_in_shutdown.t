#! /usr/bin/perl -T

use strict;
use warnings FATAL => 'all';
use Test::More tests => 2;

my $shutdown_has_run;

{   package My::Test;
    use base qw( Test::Class );
    use Test::More;

    sub foo : Test { pass("One test method must exist for shutdown to run") }
    
    sub shutdown :Test( shutdown ) {
        $shutdown_has_run = 1;
    }
    
}

My::Test->runtests( +1 );
ok $shutdown_has_run, "shutdown method has run";
