#! /usr/bin/perl -Tw

package Local::Test;
use strict;
use Test::More tests => 1;
use Test::Builder;
use base qw(Test::Class);

is_deeply(Test::Builder->new, Test::Class->builder, "builder");
