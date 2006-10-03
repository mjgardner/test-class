#! /usr/bin/perl

use strict;
use warnings;
use Test::More tests => 1;
use Test::Class;

{   package Test::Deep;
    sub isa { 1 };
}

is_deeply [ Test::Class->_test_classes ], [ 'Test::Class' ],
    'Test::Deep is not included as a test class, even though isa always returns true';