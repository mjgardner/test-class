package Discuss::User;
use base qw(Discuss::Base);

use strict;
use warnings;
use Discuss::Carp;
use Discuss::Exceptions qw(throw_invalid_email);
use Discuss::Topic;
use Mail::CheckUser qw(check_email);

our $VERSION = '0.10';

sub table		{ 'users' };
sub columns		{ [ qw( user_id email name password banned ) ] };
sub required	{ [ qw( email name password ) ] };
sub default		{ [ banned => 0 ] };

sub new {
	my ($class, %param) = @_;
	local $Mail::CheckUser::Skip_Network_Checks = 1;
	throw_invalid_email $param{email} unless check_email( $param{email} );
	$class->SUPER::new(%param);
};

1;
