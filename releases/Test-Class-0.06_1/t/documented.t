#! /usr/bin/perl -w

use strict;
use warnings;
use Test::More;
eval "use Test::Pod::Coverage 0.04";
plan skip_all => "Test::Pod::Coverage required" if $@;
plan tests => 1;
pod_coverage_ok(
    "Test::Class",
    { pod_from => 'lib/Test/Class.pod' },
    "Test::Class pod coverage",
);
