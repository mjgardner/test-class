#! /usr/bin/perl

use strict;
use warnings;
use Test::Exception tests => 1;

{   package SomeClassThatDefinesNew;
    sub new { return bless {}, shift };
}

{   package TestClassWithBrokenMI;
    use base qw( SomeClassThatDefinesNew Test::Class ); 
}

throws_ok { Test::Class->runtests } qr/Test::Class internals seem confused/,
    'sensible error if new() is overridden';