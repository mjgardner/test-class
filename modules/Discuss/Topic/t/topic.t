#! /usr/bin/perl 

use strict;
use warnings;
use Test::More 'no_plan';
use Discuss::Tables qw(clear_all_tables);
use Discuss::DBI;
use Test::DBI;
use Test::Exception;
use Discuss::Board;

BEGIN { use_ok('Discuss::Topic') };

my $dbh = Discuss::DBI->connect;

clear_all_tables($dbh);

my $hidden = Discuss::Board->new(name => 'hidden', dbh => $dbh);
my $live = Discuss::Board->new(name => 'live', dbh => $dbh, 
		status => 'live');
my $static = Discuss::Board->new(name => 'static', dbh => $dbh, 
		status => 'live', type => "static");
my $noreply = Discuss::Board->new(name => 'noreply', dbh => $dbh, 
		status => 'live', type => "noreply");

isa_ok(my $t1 = Discuss::Topic->new(
	dbh => $dbh, board_id=> $hidden->board_id, name => 'topic1'
), 'Discuss::Topic', 't1');
row_count_is($dbh, Discuss::Topic->table, 1);

is $t1->topic_id, 1, 'id = 1';
is $t1->name, 'topic1', 'name = topic1';
is $t1->num_posts, 0, 'num_posts default';
is $t1->board_id, $hidden->board_id, 'board_id set';
isa_ok $t1->board, 'Discuss::Board', 'topic->board';
is $t1->board->board_id, $t1->board_id, 'topic->board correct';
ok !$t1->can_post, 'cannot post to hidden board';

my $t2 = Discuss::Topic->new(dbh => $dbh, board_id=> $live->board_id, 
		name => 'topic2', num_posts => 40);
ok $t2->can_post, 'can post to live board';

my $t3 = Discuss::Topic->new(dbh => $dbh, board_id=> $static->board_id,
		name => 'topic3', num_posts => 3);
ok !$t3->can_post, 'cannot post to static board';
		
my $t4 = Discuss::Topic->new(dbh => $dbh, board_id=> $noreply->board_id, 
		name => 'topic4', num_posts => 0);
ok $t4->can_post, 'can post to empty topic on noreply board';
$t4->num_posts++;
ok !$t4->can_post, 'cannot post to topic with post on noreply board';

sub test_iterator {
	my ($i, @order) = @_;
	foreach my $n  (@order) {
		my $o = $i->next;
		isa_ok($o, 'Discuss::Topic', "o$n");
		is($o->topic_id, $n, "o$n id");
		is($o->name, "topic$n", "o$n name");
	};
	is($i->next, undef, 'undef on last record');
};

my $i = Discuss::Topic->iterator(dbh => $dbh);
isa_ok $i, 'Discuss::DBIObject::Iterator';
isa_ok $i, 'Discuss::Base::Iterator';
test_iterator($i, 1, 2, 3, 4);

test_iterator(Discuss::Topic->iterator(dbh=>$dbh)->by_name(2),1,2);
test_iterator(Discuss::Topic->iterator(dbh=>$dbh)->most_popular(2),2,3);
test_iterator(Discuss::Topic->iterator(dbh=>$dbh)->most_recent(2),4,3);

$t1->num_posts++;
is $t1->num_posts, 1, 'num_posts incremented';