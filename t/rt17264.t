#! /usr/bin/perl

use strict;
use warnings;
use Test::Exception tests => 1;

use lib 't/rt17264';
require 'Test/Class.pm';

throws_ok { Test::Class->runtests } qr/Test::Class was loaded too late/,
    'we figured out that we loaded Test::Class too late';