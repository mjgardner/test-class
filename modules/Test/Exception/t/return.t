#! /usr/bin/perl -Tw

use strict;
use Test::Builder;
use Test::Harness;
use Test::More tests => 13;

BEGIN { use_ok( 'Test::Exception' ) };

sub div {
   my ($a, $b) = @_;
   return( $a / $b );
};

my $ok;

$ok = 0;
$ok = dies_ok { div(1, 0) } 'dies_ok succeeded';
ok($ok, 'dies_ok returned true on success');

TODO: {
	$ok = 1;
	local $TODO = "testing dies_ok failure";
	$ok = dies_ok { div(1, 1) } 'dies_ok failed';
};
ok(!$ok, 'dies_ok returned false on failure');


$ok = 0;
$ok = throws_ok { div(1, 0) } '/./', 'throws_ok succeeded';
ok($ok, 'throws_ok returned true on success');

TODO: {
	$ok = 1;
	local $TODO = "testing throws_ok failure";
	$ok = throws_ok { div(1, 1) } '/./', 'throws_ok failed';
};
ok(!$ok, 'throws_ok returned false on failure');


$ok = 0;
$ok = lives_ok { div(1, 1) } 'lives_ok succeeded';
ok($ok, 'lives_ok returned true on success');

TODO: {
	$ok = 1;
	local $TODO = "testing lives_ok failure";
	$ok = lives_ok { div(1, 0) } 'lives_ok failed';
};
ok(!$ok, 'lives_ok returned false on failure');


