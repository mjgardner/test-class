package Account;

use strict;
use warnings;

sub new {
	my $class = shift;
	my $self = {
		transactions => [],
	};
	return bless $self, $class;
};

sub balance {
	my $self = shift;
	my $transactions = $self->{transactions};
	my $total = 0;
	$total += $_ foreach @$transactions;
	return($total);
};

sub _add_transaction {
    my ($self, $amount) = @_;
    my $transactions = $self->{transactions};
    push @$transactions, $amount;
};

sub credit {
    my ($self, $amount) = @_;
    $self->_add_transaction($amount);
};

sub debit {
    my ($self, $amount) = @_;
    $self->_add_transaction(-$amount);
};

sub transactions {
	my $self = shift;
	return(@{$self->{transactions}});
};

1;
