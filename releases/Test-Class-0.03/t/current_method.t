#! /usr/bin/perl -Tw

package Local::Test;
use strict;
use Test::More tests => 4;
use base qw(Test::Class);

sub test : Test {
	my $self = shift;
	is($self->current_method, "test", "current_method in method"); 
};

sub teardown : Test(setup => teardown => 1) {
	my $self = shift;
	is($self->current_method, "test", "current_method in setup/teardown"); 
};

__PACKAGE__->runtests;

ok(!defined(__PACKAGE__->current_method), "current_test outside runtests");
