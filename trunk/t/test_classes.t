#! /usr/bin/perl -T

use strict;
use warnings;
use Test::More tests => 1;
use Test::Exception;
use Test::Class;

lives_and {
    # Devel::Symdump::packages returns 0 in the list of packages on some
    # platforms. Don't yet understand why.
    no warnings;
    local *Devel::Symdump::packages = sub { 0, 'Test::Class' };
    is_deeply( [Test::Class->_test_classes], [ 'Test::Class' ] );
} '_test_classes deals with undef values';

