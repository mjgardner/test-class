#! /usr/bin/perl

use Test::More;
plan skip_all => "TEST_SIGNATURE must be true to test signature"
    unless $ENV{TEST_SIGNATURE};
plan skip_all => "do not test signature in development"
    if -e '.svn';
eval "use Test::Signature";
plan skip_all => "Test::Signature required to test signature" if $@;
plan tests => 1;
signature_ok();
