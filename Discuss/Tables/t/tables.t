#! /usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';

BEGIN { use_ok qw(Discuss::Tables), qw(list_tables) };

is_deeply [ list_tables() ], [ qw(boards posts topics users) ], 'list tables';
