#! /usr/bin/perl -T

use strict;
use warnings;
use Test::Class;

my @CALLED = ();

{
    package Base::Test;
    use base qw(Test::Class);
    Base::Test->SKIP_CLASS( 1 );
    sub setup : Test { die "this should not run" }
}

{
    package A::Test;
    use base qw(Base::Test);
    use Test::More;
    sub setup : Test {
        pass 'non skipping test class run as expected';
        push @CALLED, 'A::Test'
    }
}

package main;
use Test::More tests => 5;

ok(! Test::Class->SKIP_CLASS,   'Test::Class->SKIP_CLASS default' );
ok(  Base::Test->SKIP_CLASS,    'Base::Test->SKIP_CLASS overridden' );
ok(! A::Test->SKIP_CLASS,       'A::Test->SKIP_CLASS default' );

Base::Test->runtests;
is_deeply(
    [sort @CALLED], [ qw(A::Test) ], 
    'runtests skipped classes with SKIP_CLASS set'
);
