#! /usr/bin/perl -w

# Rip-off of the example given in the JUnit tutorial at 
# http://junit.sourceforge.net/doc/testinfected/testing.htm

use strict;
use warnings;


package Money;

sub new {
	my $class = shift;
	my ($currency, $amount) = @_;
	my $self = {currency => $currency, amount => $amount};
	return bless $self, $class;
};

sub amount {
	my $self = shift;
	return($self->{amount});
};

sub currency {
	my $self = shift;
	return($self->{currency});
};

sub add {
	my ($o1, $o2) = @_;
	my $currency = $o1->currency;
	my $result = $o1->amount + $o2->amount;
	return(Money->new($currency => $result));
};

sub equals {
	my ($o1, $o2) = @_;
	return(0) unless UNIVERSAL::isa ($o2, ref($o1));
	return ($o1->currency eq $o2->currency && $o1->amount eq $o2->amount);
};


package Local::Test::Money;
use base qw(Test::Class);
use Test::More;

my ($o1, $o2);

sub setup : Test(setup) {
	$o1 = Money->new(USD => 12);
	$o2 = Money->new(USD => 14);
};

sub add : Test(2) {
	my $o3 = $o1->add($o2);
	is($o3->amount, 26, 'add amount matches');
	is($o3->currency, 'USD', 'add currency matches');
};

sub equals : Test(4) {
	my $o3 = Money->new(USD => 12);
	ok(! $o1->equals(undef), 'does not equal undef');
	ok($o1->equals($o1), 'equals self');
	ok($o1->equals($o3), 'equals copy of self');
	ok(! $o1->equals($o2), 'does not equal different object');
}

package main;

Local::Test::Money->new->runtests;
