#! /usr/bin/perl -T

use strict;
use warnings FATAL => 'all';
use Test::Exception;
use Test::More tests => 2;

BEGIN { use_ok 'Test::Class' };

dies_ok { Test::Class->runtests( 'Not::A::Test::Class' ) } 
    'runtests dies if we are given something that is not a test class';
