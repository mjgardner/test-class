#! /usr/bin/perl -w

package Account::Test;
use base qw(Test::Class);
use strict;
use Test::More;
use Test::Exception;
use Account;

sub account_fixture : Test(setup) {
	my $self = shift;
	$self->{account} = Account->new;
};

sub account_creation : Test {
	my $account = shift->{account};
	isa_ok($account, 'Account');
};

sub balance : Test {
	my $account = shift->{account};
	is($account->balance, 0, 'initial balance zero');
};

sub credit : Test(4) {
	my $account = shift->{account};
	lives_ok {$account->credit(10)} 'credit 10 worked';
	is($account->balance, 10, 'new balance 10');
	lives_ok {$account->credit(32)} 'credit 32 worked';
	is($account->balance, 42, 'new balance 42');
};

sub credit_transactions : Test(4) {
	my $account = shift->{account};
	lives_ok {$account->credit(10)} 'credit 10 worked';
	lives_ok {$account->credit(32)} 'credit 32 worked';
	lives_ok {$account->debit(10)} 'debit 10 worked';
    my @transactions = $account->transactions;
    is_deeply(\@transactions, [10, 32, -10], 'transactions ok');
};

sub debit : Test(4) {
	my $account = shift->{account};
	lives_ok {$account->debit(10)} 'debit 10 worked';
	is($account->balance, -10, 'new balance -10');
	lives_ok {$account->debit(32)} 'debit 32 worked';
	is($account->balance, -42, 'new balance -42');
};

Account::Test->runtests;
