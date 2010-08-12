#! /usr/bin/perl

use strict;
use warnings;

{

    package Foo;
    use base qw(Test::Class);
    use Test::More;

    sub startup : Tests(startup) {
        my $self = shift;
        fail("No startup classes without test methods");
    }
    sub shutdown : Tests(shutdown) {
        my $self = shift;
        fail("No shutdown classes without test methods");
    }
}

{

    package Bar;
    use base qw(Foo);
    use Test::More;

    # deliberately overridding parent versions
    sub startup : Tests(startup) {}
    sub shutdown : Tests(shutdown) {}

    sub passN {
        my ( $self, $n ) = @_;
        my $m = $self->current_method;
        pass("$m just passing $_") foreach ( 1 .. $n );
    }

    sub two_tests : Tests {
        $_[0]->passN(2);
    }

    sub some_test : Tests {
        $_[0]->passN(2);
    }
}

package main;
use Test::More tests => 4;

Test::Class->runtests;
