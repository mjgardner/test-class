package Discuss::Board;
use base qw(Discuss::Base);

use strict;
use warnings;
use Discuss::Topic;

our $VERSION = '0.17';

sub table { 'boards' };

sub columns { [ qw( 
	board_id name num_posts status type description link
) ] };

sub required { [ qw( name ) ] };

sub default { [ 
	type => 'normal', status => 'hidden', num_posts => 0, 
	description => '', link => ''
] };

sub is_html { [ 'description' ] };

sub num_posts : lvalue	{ ${+shift}->{num_posts} };

sub topics {
	my $self = shift;
	Discuss::Topic
		->iterator( dbh => $$self->{dbh} )
		->where( board_id => $$self->{board_id} );
};

sub can_post {
	my $self = shift;
	$self->status eq 'live' && $self->type ne 'static'		
};

sub is_live {
	$_[0]->status eq 'live';
}

1;
