#! /usr/bin/perl -T

use strict;
use warnings;

package Local::Test;
use Test::More tests => 4;
use base qw(Test::Class);

sub test : Test {
	my $self = shift;
	is($self->current_method, "test", "current_method in method"); 
};

sub setup : Test(setup => 1) {
	my $self = shift;
	is($self->current_method, "test", "current_method in setup"); 
};

sub teardown : Test(teardown => 1) {
	my $self = shift;
	is($self->current_method, "test", "current_method in teardown"); 
};

__PACKAGE__->runtests;

ok(!defined(__PACKAGE__->current_method), "current_test outside runtests");
