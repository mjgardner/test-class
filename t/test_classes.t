#! /usr/bin/perl -T

use strict;
use warnings;
use Test::More tests => 1;
use Test::Exception;
use Test::Class;

lives_and {
    # Devel::Symdump::packages returns undef values... 
    # don't yet know why
    no warnings;
    local *Devel::Symdump::packages = sub { undef, 'Test::Class' };
    is_deeply( [Test::Class->_test_classes], [ 'Test::Class' ] );
} '_test_classes deals with undef values';

