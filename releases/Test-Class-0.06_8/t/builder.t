#! /usr/bin/perl -T

use strict;
use warnings;

package Local::Test;
use Test::More tests => 1;
use Test::Builder;
use base qw(Test::Class);

is_deeply(Test::Builder->new, Test::Class->builder, "builder");
