#! /usr/bin/perl

use Test::More tests => 1;
plan skip_all => "Skipping signature test in dev environment" if -e '.svn';
eval "use Test::Signature";
plan skip_all => "Test::Signature required to test signature" if $@;
signature_ok();
