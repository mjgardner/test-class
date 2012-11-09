#! /usr/bin/perl

use strict;
use warnings;
use Test::More tests => 1;

BEGIN {
    use t::WarnCatch; # has to be use so that it runs earlier than BEGIN

    {
        package Base::Test;
        use base qw( Test::Class );
    }
    
    {
        package Broken::Test;
        use base qw( Base::Test );

        sub new : Test {
            "oops - we've overridden a public method with a test method";
        }
    }
}

like t::WarnCatch::Caught, qr/overriding public method/,
    'cannot override a public method with a test method';
