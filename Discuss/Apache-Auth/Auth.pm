#	<Location /protected>
#		PerlAccessHandler	Discuss::Apache::Auth
#		SetHandler			perl-script
#		PerlSetVar			Discuss::Apache::Auth::Secret "secret"
#		ErrorDocument		403 /login
#	</Location

package Discuss::Apache::Auth;

use strict;
use warnings;
use Discuss::Exceptions qw(throw_bad_auth_ticket throw_no_auth_ticket);
use Digest::MD5 qw( md5_hex );
use Apache::Constants ':response';
use CGI::Cookie;
use Discuss::Carp;

our $VERSION = '0.03';

sub new {
	my ($class, $request) = @_;
	croak "need request" unless defined $request;
	bless { request => $request, id => undef }, $class;
};

sub id {
	my $self = shift;
	return $self->{id} unless @_;
	$self->{id} = shift;
	return $self;
};

sub secret {
	my $self = shift;
	my $secret = ref($self) . '::Secret';
	$self->{request}->dir_config( $secret )
		or confess "$secret dir config not set";
};

sub ticket {
	my ($self, $id) = @_;
	$id ||= $self->id or confess "no id set";
	return $id . ":" . md5_hex($self->secret . $id);
};

sub cookie_name {
	my $self = shift;
	ref($self) . "::Ticket";
};

sub set_cookie {
	my $self = shift;
	my $cookie = CGI::Cookie->new(
		'-path' => '/',
		'-expires' =>  '+12M',
		'-name' => $self->cookie_name,
		'-value' => $self->ticket,
	);
	$self->{request}->header_out( "Set-Cookie" => $cookie->as_string );
	return $self;
};

sub fetch_cookie {
	my $self = shift;
	my $cookies = CGI::Cookie->fetch( $self->{request} )
		or throw_no_auth_ticket $self->cookie_name;
	my $cookie = $cookies->{$self->cookie_name}
		or throw_no_auth_ticket $self->cookie_name;
	my $ticket = $cookie->value;
	throw_bad_auth_ticket name => $self->cookie_name, value => $ticket 
		unless $ticket =~ m/^(\d+):/ && $ticket eq $self->ticket($1);
	return $self->id($1)->set_cookie;
};

sub clear_cookie {
	my $self = shift;
	my $cookie = CGI::Cookie->new(
		'-path' => '/',
		'-expires' =>  '-1d',
		'-name' => $self->cookie_name,
		'-value' => ''
	);
	$self->{request}->header_out( "Set-Cookie" => $cookie->as_string );
	return $self;
};

sub handler($$) {
	my ($class, $r) = @_;
	$r->log_reason("class is $class request is $r");
	eval { $class->new($r)->fetch_cookie($r) };
	if ($@) {
		$r->log_reason($@, $r->filename);
		return(FORBIDDEN);
	};
	return(OK);
};

1;
