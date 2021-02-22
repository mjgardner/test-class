#!/usr/bin/env perl

use strict;
use warnings;
use autodie;
use Test::More tests => 1;

use parent qw( Test::Class );

sub test_fork : Tests() {
    my $pid = fork or do {
        exit;
    };

    waitpid $pid, 0;
    ok 1, 'in parent';
}

__PACKAGE__->new()->runtests() if !caller;

# See https://rt.cpan.org/Public/Bug/Display.html?id=128491
