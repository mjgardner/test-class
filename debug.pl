#! /usr/bin/perl 

use strict;
use warnings;
use Symbol qw(delete_package);
use Test::More;

my %variants = (

  adrianh_no_warnings => q{
    use constant DEBUG => do {
      my ($package, $debug) = (__PACKAGE__, $ENV{DEBUG} || ''); 
      ",$debug," =~ m/,($package|all)(=(.*?))?,/s && ($2 ? $3 : 1)
    };
  },

  aristotle => q{
	use constant DEBUG => do {
	   my %dlv = map /^(.+?)(?:=(\d+))?$/, split /,/, $ENV{DEBUG} || '';
	   $dlv{(__PACKAGE__)} || exists $dlv{(__PACKAGE__)}
	   || $dlv{all} || exists $dlv{all};
	};
  },
);

my %test_values = (
  'Foo::Bar'         =>  1,
  'all'              =>  1,
  ''                 =>  '',
  'bar'              =>  '',
  undef              =>  '',
  'Foo::Bar=99,bar'  => 99,
  'bar,Foo::Bar=99', => 99,
  'all=99,bar'       => 99,
  'bar,all=99',      => 99,
);

plan tests => scalar(keys(%test_values)) * scalar(keys(%variants));

while (my ($variant, $test_constant) = each %variants) {
  while (my ($debug, $expected) = each %test_values ) {
    delete_package('Foo::Bar');
    if ($debug eq 'undef') {
      delete $ENV{'DEBUG'};
    } else {
      $ENV{'DEBUG'} = $debug;
    };
    eval qq{
      package Foo::Bar;
      use strict;
      use warnings;
      $test_constant;
      main::is(DEBUG, \$expected, "\$variant: \$debug");
    }; fail($@) if $@;
  };
};

