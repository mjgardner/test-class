#! /usr/bin/perl

use strict;
use warnings;

package main;

use Test::Class;
use Test::More tests => 1;

eval {
    Test::Class->add_filter( 'not a sub' );
};
like( $@, qr/^Filter isn't a code-ref/, "error on non-coderef filter" );
