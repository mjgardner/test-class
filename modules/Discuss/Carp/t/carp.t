#! /usr/bin/perl

use strict;
use warnings;
use Test::More 'no_plan';
use Test::Exception;

BEGIN { use_ok 'Discuss::Carp' };

sub foo {
	carp("goodbye cruel world");
};

sub bar { eval{ foo() }; return $@ };

my $message = bar();
my $expected = <<'EOT';
goodbye cruel world
main::foo, .*?carp.t line \d+
\(eval\), .*?carp.t line \d+
main::bar, .*?carp.t line \d+
EOT

like $message, qr/^$expected$/s, 'message ok';

# NOTE: We have this private Carp variant because
# there seems to be a bug in the 5.8 version that 
# gives a "free" warning in some situations