#! /usr/bin/perl

use strict;
use warnings;
use Test::More 'no_plan';
use Test::Exception;

BEGIN { use_ok ('Test::Block') };

dies_ok { Test::Block->plan } 'must specify num tests to run';
dies_ok { Test::Block->plan('foo') } 
    'value only num tests must be a number';
dies_ok { Test::Block->plan(tests => 'foo') }
    'key/value num tests must be a number';