#! /usr/bin/perl

use strict;
use warnings;
use Test::More tests => 1;

my $warning;

BEGIN {

    $SIG{ __WARN__ } = sub { $warning = "@_" };

    {
        package Base::Test;
        use base qw( Test::Class );
    };
    
    {
        package Broken::Test;
        use base qw( Base::Test );

        sub new : Test {
            "oops - we've overridden a public method with a test method";
        }
    }
}

like $warning, qr/overriding public method/,
    'cannot override a public method with a test method';
