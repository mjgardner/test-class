package Discuss::Plugin::User::Boards;
use base qw( Template::Plugin );

use strict;
use warnings;

use Discuss::Board;
use Discuss::Topic;
use Discuss::Post;
use Discuss::Exceptions qw(throw_board_not_live throw_no_current_post);
use Discuss::DBI;
use Discuss::Carp;

our $VERSION = '0.24';

sub new {
	my ($class, $context) = @_;
	bless { 
		_dbh => Discuss::DBI->connect, 
		_context => $context,
		_page_size => 10,
		_max_page_size => 100,
	}, $class
};

sub _live_boards {
	my $self = shift;
	Discuss::Board->iterator( dbh=>$self->{_dbh} )
		->where( status=>'live' );
};

sub by_name {
	my $self = shift;
	_live_boards($self)->by_name(@_);
};

sub most_recent {
	my $self = shift;
	_live_boards($self)->most_recent(@_);
};

sub most_popular {
	my $self = shift;
	_live_boards($self)->most_popular(@_);
};

sub page_size {
	my ($self, $page_size) = @_;
	$self->{_page_size} = $page_size
		if $page_size && $page_size =~ m/^\d+$/ && $page_size > 0
		&& $page_size <= $self->max_page_size;
	$self->{_page_size};
};

sub max_page_size {
	my $self = shift;
	@_ ? $self->{_max_page_size} = shift : $self->{_max_page_size};
};

sub _get_from_uri {
	my ($self, $key) = @_;
	return unless my $r = $self->{_context}->stash->{_request};
	$r->uri =~ m!$key/(\d+)! ? $1 : undef;
};

sub current_board {
	my $self = shift;
	return $self->{_current_board} if exists $self->{_current_board};
	return $self->{_current_board} = $self->current_topic->board
		if $self->current_topic;
	return $self->{_current_board} = undef
		unless _get_from_uri($self, 'board');
	my $board = Discuss::Board->fetch(
		dbh => $self->{_dbh}, board_id => _get_from_uri($self, 'board')
	);
	throw_board_not_live $board->board_id unless $board->is_live;
	return $self->{_current_board} = $board;
};

sub current_topic {
	my $self = shift;
	return $self->{_current_topic} if exists $self->{_current_topic};
	return $self->{_current_topic} = undef
		unless _get_from_uri($self, 'topic');
	my $topic = Discuss::Topic->fetch(
		dbh => $self->{_dbh}, topic_id => _get_from_uri($self, 'topic')
	);
	throw_board_not_live $topic->board->board_id
		unless $topic->board->is_live;
	return $self->{_current_topic} = $topic;
};

sub num_posts {
	my $self = shift;
	($self->current_topic || $self->current_board)->num_posts
};

sub _post_iterator {
	my $self = shift;
 	my $i = Discuss::Post->iterator(dbh => $self->{_dbh}, lazy => 1)
 				->order_by('posts.post_id')->order('desc');
 	if (my $topic = $self->current_topic ) {
		$i->where(topic_id => $topic->topic_id);
	} else {
		$i->join_with(
			'posts.topic_id'	=> 'topics.topic_id',
			'topics.board_id'	=> 'boards.board_id'
		)->where('boards.board_id' => $self->current_board->board_id);
	};
	return $i;
};

sub _set_page_info {
	my $self = shift;
	my $i = _post_iterator( $self )->limit($self->page_size+1);
	my $holds_all_posts = $self->page_size >= $self->num_posts;
	my $post_id = _get_from_uri($self, 'post');
	$i->where_op('<=', post_id => $post_id)
		if $post_id && !$holds_all_posts;
	my $posts = $self->{_posts} = $i->as_list;
	throw_no_current_post unless @$posts;
	$self->{_current_post} = $posts->[0];
	if ($holds_all_posts) {		
		$self->{_next_post} = $self->{_last_post} = undef;
	} else {
		$self->{_last_post}
			= @$posts == 1+$self->page_size && pop @$posts || undef;
		$self->{_next_post} = _post_iterator($self)->order('asc')
			->limit($self->page_size)
			->where_op('>', post_id => $posts->[0]->post_id)
			->as_list->[-1];
	};
	Discuss::Post->load_all(@$posts);
};

sub _fetch_page_info {
	my ($self, $info) = @_;
	_set_page_info( $self) unless exists $self->{$info};
	return $self->{$info};
};

sub next_post { shift->_fetch_page_info('_next_post') };
sub last_post { shift->_fetch_page_info('_last_post') };
sub current_post { shift->_fetch_page_info('_current_post') };
sub posts { shift->_fetch_page_info('_posts') };

sub _make_page_path {
	my ($self, $post) = @_;
	return unless $post;
	my @path = ();
	push @path, board => $self->current_board->board_id
		if $self->current_board;
	push @path, topic => $self->current_topic->topic_id
		if $self->current_topic;
	return join('/', @path, post => $post->post_id);
}

sub current_page { 
	my $self = shift;
	_make_page_path( $self, $self->current_post )
};

sub next_page { 
	my $self = shift;
	_make_page_path( $self, $self->next_post )
};

sub last_page { 
	my $self = shift;
	_make_page_path( $self, $self->last_post )
};

sub post_page {
	my $self = shift;
	_make_page_path( $self, @_ )
}

sub board_page {
	my $self = shift;
	return unless my $board = $self->current_board;
	join( '/', board => $board->board_id);
};

sub topic_page {
	my $self = shift;
	return unless my $topic = $self->current_topic;
	join( '/', board => $topic->board->board_id, 
		topic => $topic->topic_id);
};

1;
