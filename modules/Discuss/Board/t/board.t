#! /usr/bin/perl 

use strict;
use warnings;
use Test::More 'no_plan';
use Discuss::Tables qw(clear_all_tables);
use Discuss::DBI;
use Test::DBI;
use Test::Exception;
use Discuss::Topic;

BEGIN { use_ok('Discuss::Board') };

my $dbh = Discuss::DBI->connect;
my $table = 'boards';

clear_all_tables($dbh);

isa_ok(my $b1 = Discuss::Board->new(dbh => $dbh, name => 'board1'), 'Discuss::Board', 'b1');
row_count_is($dbh, $table, 1);
is $b1->board_id, 1, 'id = 1';
is $b1->name, 'board1', 'name = board1';
is $b1->type, 'normal', 'type default';
is $b1->status, 'hidden', 'status default';
ok !$b1->is_live, 'board hidden';
is $b1->description, '', 'description default';
is $b1->link, '', 'link default';
is $b1->num_posts, 0, 'num_posts default';
$b1->num_posts++;
is $b1->num_posts, 1, 'num_posts incremented';
ok !$b1->can_post, 'cannot post to hidden board';

isa_ok(my $b2 = Discuss::Board->new(dbh => $dbh, name => 'board2', status => 'live', description => '<p>description</p>', link => 'a&b'), 'Discuss::Board', 'b2');
row_count_is($dbh, $table, 2);
is $b2->board_id, 2, 'id = 2';
is $b2->name, 'board2', 'name = board2';
is $b2->type, 'normal', 'type default';
is $b2->status, 'live', 'status set';
ok $b2->is_live, 'board live';
is $b2->description, '<p>description</p>', 'description set';
is $b2->link, 'a&b', 'link set';
{
	local $Discuss::Base::Escape_html = 1;
	is $b2->description, '<p>description</p>', 'description not escaped';
	is $b2->link, 'a&amp;b', 'links escaped';
};
ok $b2->can_post, 'can post to live board';

isa_ok(my $b3 = Discuss::Board->new(dbh => $dbh, name => 'board3', type => 'static', status=> 'live'), 'Discuss::Board', 'b3');
row_count_is($dbh, $table, 3);
is $b3->board_id, 3, 'id = 3';
is $b3->name, 'board3', 'name = board3';
is $b3->status, 'live', 'status set';
is $b3->type, 'static', 'type set';
ok !$b3->can_post, 'cannot post to static board';

isa_ok(my $b4 = Discuss::Board->new(dbh => $dbh, name => 'board4', type => 'noreply', status=> 'live'), 'Discuss::Board', 'b4');
row_count_is($dbh, $table, 4);
is $b4->board_id, 4, 'id = 4';
is $b4->name, 'board4', 'name = board4';
is $b4->status, 'live', 'status set';
is $b4->type, 'noreply', 'type set';
ok $b4->can_post, 'can post to empty noreply board';
$b4->num_posts++;
ok $b4->can_post, 'can post to a noreply board with a post';

throws_ok {
	Discuss::Board->new(dbh => $dbh, name => 'board1')
} 'Discuss::Exception::Duplicate';
row_count_is($dbh, $table, 4);

dies_ok {$b1->iterator(dbh => $dbh)} 'cannot use object to fetch other objects';

my $t1 = Discuss::Topic->new(dbh => $dbh, board_id=>1, name => 't1');
my $t2 = Discuss::Topic->new(dbh => $dbh, board_id=>1, name => 't2');
my $t3 = Discuss::Topic->new(dbh => $dbh, board_id=>2, name => 't3');

{
my $topics = $b1->topics;
is $topics->next->name, 't1', 'found t1';
is $topics->next->name, 't2', 'found t2';
is $topics->next, undef, 'found undef';
}

{
my $topics = $b2->topics;
is $topics->next->name, 't3', 'found t3';
is $topics->next, undef, 'found undef';
}

{
my $topics = $b3->topics;
is $topics->next, undef, 'found undef';
}
