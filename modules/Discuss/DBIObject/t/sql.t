#! /usr/bin/perl

use strict;
use warnings;
use Test::More 'no_plan';
use Test::Exception;
use DBI;

BEGIN {
	use_ok 'Discuss::DBIObject::SQL';
};

my $dbh = DBI->connect(undef, undef, undef, {
	RaiseError => 1, PrintError=>0, ShowErrorStatement=>1
});

isa_ok my $o = Discuss::DBIObject::SQL->new(dbh => $dbh), 
		'Discuss::DBIObject::SQL';

dies_ok { Discuss::DBIObject::SQL->new } 'must supply dbh';
foreach my $method (qw(from order_by order limit where_op)) {
	dies_ok { $o->$method(undef) } "$method must be defined";
	dies_ok { $o->$method('#') } "$method must be legal";
};

dies_ok { $o->from('foo')->where('#' => 2) } 'bad column name in where';
dies_ok { $o->from('foo')->where('column') } 'no value in where';
dies_ok { $o->from('foo')->join_with('column') } 'no value in join_with';
