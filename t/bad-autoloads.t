#! /usr/bin/perl

use strict;
use warnings FATAL => 'all';
use Test::More;

BEGIN {
    no warnings;
    eval "use Contextual::Return";
    if ($@ ) {
        plan skip_all => "need Contextual::Return" if $@;
    } else {
        plan tests => 2;
        use_ok 'Test::Class';
    }
}

{
    our $is_warning_free = 1;
    $SIG{ __WARN__ } = sub { $is_warning_free = 0 };
    Test::Class->_isa_class( 'Contextual::Return::Value' );
    ok $is_warning_free, 'avoided warnings from Contextual::Return::Value';
}