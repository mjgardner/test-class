#! /usr/bin/perl

use strict;
use warnings;
use Test::More tests => 2;
use Discuss::DBI;

is $Discuss::DBI::VERSION, '0.08', 'version updated';
ok("acceptance tests run");