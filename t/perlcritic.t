#! /usr/bin/perl

use strict;
use warnings;

use Test::More;

unless ( $ENV{AUTOMATED_TESTING} or $ENV{RELEASE_TESTING} ) {
	plan( skip_all => "Author tests not required for installation" );
}

eval "use Test::Perl::Critic (-profile => 't/perlcriticrc')";
plan skip_all => "Test::Perl::Critic required for criticism" if $@;
all_critic_ok();


