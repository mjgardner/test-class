#!/usr/bin/perl -Tw

# Make sure caller() is undisturbed.

use strict;
use Test::More tests => 3;

BEGIN {use_ok('Test::Exception')};

eval { die caller() . "\n" };
is( $@, "main\n" );

throws_ok { die caller() . "\n" }  qr/^main$/;