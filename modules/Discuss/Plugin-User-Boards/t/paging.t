use strict;
use warnings;
use Test::More 'no_plan';
use Apache::FakeRequest;
use Discuss::Board;
use Discuss::Topic;
use Discuss::Post;
use Discuss::User;
use Discuss::Tables qw(clear_all_tables);
use Template::Context;

my $class;
BEGIN {
	$class = 'Discuss::Plugin::User::Boards';
	use_ok ( $class );
};

my $dbh = Discuss::DBI->connect;
clear_all_tables($dbh);

my $user = Discuss::User->new( name => 'test', email => 'email@foo.com',
	password => 'foo', dbh => $dbh );

my ($b1, $b2) = map {
	Discuss::Board->new( dbh => $dbh, name => "b$_", status => 'live' )
} (1..2);

my ($b1t1, $b1t2) = map {
	Discuss::Topic->new( dbh => $dbh, name => 'b1t$_', 
		board_id => $b1->board_id )
} (1..2);

my $b2t1 = Discuss::Topic->new( dbh => $dbh,
	name => 'topic in second board', board_id => $b2->board_id );

my @posts;
foreach my $post (1..4) {
	foreach my $topic ($b1t1, $b1t2) {
		my $post = Discuss::Post->new( 
			dbh => $dbh,
			content => "b1t" . $topic->topic_id . "p$post", 
			topic_id => $topic->topic_id, 
			user_id => $user->user_id 
		);
		push @posts, {id => $post->post_id, content => $post->content};
	};
};

Discuss::Post->new( dbh => $dbh, content => 'post in second board', 
	topic_id => $b2t1->topic_id, user_id => $user->user_id );

sub make_with_uri {
	my $uri = shift;
	$class->new(
		Template::Context->new(
			VARIABLES => {
				_request => Apache::FakeRequest->new(uri => $uri)
			}
		)
	);
};

{
	package MockPost;
	sub new { bless {}, shift };
	sub post_id { 9999 };
};

{
	my $o = make_with_uri('http://localhost/board/' . $b1->board_id);
	is $o->num_posts, 8, 'num_posts for board';
	$o->page_size(3);
	is $o->current_page, 
		'board/' . $b1->board_id . '/post/' . $posts[7]->{id},
		'current_page from board';
	ok !$o->next_page, 'no next_page for board';
	is $o->last_page, 
		'board/' . $b1->board_id . '/post/' . $posts[4]->{id},
		'last_page from board';
	is $o->board_page, 'board/' . $b1->board_id, 'board_page';
	ok !$o->topic_page, 'no topic_page for board';
	is $o->post_page( MockPost->new ), 
		'board/' . $b1->board_id . '/post/9999',
		'post_page for board';
};

{
	my $o = make_with_uri('http://localhost/topic/' . $b1t2->topic_id);
	is $o->num_posts, 4, 'num_posts for topic';
	is $o->current_page, 
		'board/' . $b1->board_id 
		. '/topic/' . $b1t2->topic_id 
		. '/post/' . $posts[-1]->{id},
		'current_page from topic';
	is $o->topic_page, 'board/' . $b1->board_id . '/topic/' 
		. $b1t2->topic_id, 'topic_page from topic';
	is $o->post_page( MockPost->new ), 
		'board/' . $b1->board_id . '/topic/' . $b1t2->topic_id 
			. '/post/9999',
		'post_page for topic';
};

sub check_page {
	my %param = @_;
	my $o = make_with_uri( $param{uri} );
	$o->page_size( $param{page_size} );
	ok($o->next_post->is_lazy, "$param{name} (next lazy)") if $param{next};
	is defined $param{next} ? $o->next_post->content : $o->next_post, 
		$param{next}, "$param{name} (next)";
	ok($o->last_post->is_lazy, "$param{name} (last lazy)") if $param{last};
	is defined $param{last} ? $o->last_post->content : $o->last_post, 
		$param{last}, "$param{name} (last)";
	ok( not(scalar grep {$_->is_lazy} @{$o->posts}), 
		"$param{name} (all posts loaded)");
	is_deeply [ map { $_->content} @{$o->posts} ], $param{posts},
		"$param{name} (posts)";
	is $o->current_post, $o->posts->[0], "$param{name} (current)";
}

# Test paging across whole board

my $board_uri = 'http://localhost/board/' . $b1->board_id;

check_page(
	name => '3 post page, board, at end',
	uri => $board_uri,
	page_size => 3,
	next => undef,
	last => 'b1t1p3',
	posts => [ 'b1t2p4', 'b1t1p4', 'b1t2p3'],
);

check_page(
	name => '3 post page, board, at start',
	uri => $board_uri . '/post/' . $posts[0]->{id},
	page_size => 3,
	next => 'b1t2p2',
	last => undef,
	posts => [ 'b1t1p1' ],
);

check_page(
	name => '3 post page, board, at start edge',
	uri => $board_uri . '/post/' . $posts[2]->{id},
	page_size => 3,
	next => 'b1t2p3',
	last => undef,
	posts => [ 'b1t1p2', 'b1t2p1', 'b1t1p1'],
);

check_page(
	name => '3 post page, board, in middle',
	uri => $board_uri . '/post/' . $posts[5]->{id},
	page_size => 3,
	next => 'b1t2p4',
	last => 'b1t1p2',
	posts => [ 'b1t2p3', 'b1t1p3', 'b1t2p2'],
);

check_page(
	name => 'page greater than num posts of board',
	uri => $board_uri . '/post/' . $posts[5]->{id},
	page_size => 99,
	next => undef,
	last => undef,
	posts => [ map { $_->{content} } reverse @posts ],
);

check_page(
	name => 'page equal num posts of board',
	uri => $board_uri . '/post/' . $posts[5]->{id},
	page_size => 8,
	next => undef,
	last => undef,
	posts => [ map { $_->{content} } reverse @posts ],
);


# Test paging across a topic

my $topic_uri = 'http://localhost/board/' . $b1->board_id . '/topic/' 
	. $b1t2->topic_id;
	
check_page(
	name => '3 post page, topic, at end',
	uri => $topic_uri,
	page_size => 3,
	next => undef,
	last => 'b1t2p1',
	posts => [ 'b1t2p4', 'b1t2p3', 'b1t2p2'],
);

check_page(
	name => '3 post page, topic, at start',
	uri => $topic_uri . '/post/' . $posts[1]->{id},
	page_size => 3,
	next => 'b1t2p4',
	last => undef,
	posts => [ 'b1t2p1' ],
);

check_page(
	name => '3 post page, topic, at start edge',
	uri => $topic_uri . '/post/' . $posts[5]->{id},
	page_size => 3,
	next => 'b1t2p4',
	last => undef,
	posts => [ 'b1t2p3', 'b1t2p2', 'b1t2p1'],
);

check_page(
	name => '2 post page, topic, in middle',
	uri => $topic_uri . '/post/' . $posts[5]->{id},
	page_size => 2,
	next => 'b1t2p4',
	last => 'b1t2p1',
	posts => [ 'b1t2p3', 'b1t2p2' ],
);

check_page(
	name => 'page greater than num posts of topic',
	uri => $topic_uri . '/post/' . $posts[5]->{id},
	page_size => 99,
	next => undef,
	last => undef,
	posts => [ 'b1t2p4', 'b1t2p3', 'b1t2p2', 'b1t2p1' ],
);

check_page(
	name => 'page equal num posts of topic',
	uri => $topic_uri . '/post/' . $posts[5]->{id},
	page_size => 4,
	next => undef,
	last => undef,
	posts => [ 'b1t2p4', 'b1t2p3', 'b1t2p2', 'b1t2p1' ],
);

