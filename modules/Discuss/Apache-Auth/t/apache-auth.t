#! /usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';
use Test::Exception;

use Apache::MyConfig;
use Apache::Constants qw(:common);
use Apache::FakeRequest;
BEGIN {
	$ENV{MOD_PERL}=1;
	use CGI::Cookie;
}

my $Class;
BEGIN { use_ok ( $Class = 'Discuss::Apache::Auth' ) };

ok $Apache::MyConfig::Setup{PERL_ACCESS}, 'have access handler';
ok $Apache::MyConfig::Setup{PERL_METHOD_HANDLERS},
	'have method handlers';

dies_ok { $Class->new } 'must supply request';

my $r = Apache::FakeRequest->new;
isa_ok(my $o = $Class->new($r), $Class);

{
	package Apache::FakeRequest;
	no warnings;
	sub dir_config {
		shift->{dir_config};
	};	
	sub header_out {
		my $self = shift;
		$self->{header_out} = {@_};
	};
}
;
$r->{dir_config} = 'mysecret';
lives_and { is $o->secret, 'mysecret' } 'secret';

is $o->id, undef, 'id default';
is $o->id(12), $o, 'id returns self on set';
is $o->id, 12, 'id set worked';

my $same = $Class->new($r)->id(12);
my $different = $Class->new($r)->id(99);

like $o->ticket, qr/^12:.*$/, 'ticket contains id';
is $o->ticket, $same->ticket, 'same id has same ticket';
isnt $o->ticket, $different->ticket, 'different id has different ticket';
is $o->ticket, $different->ticket(12), 'can explicitly set ticket id';

my $ticket1 = $o->ticket;
$r->{dir_config} = 'anothersecret';
my $ticket2 = $o->ticket;
isnt $ticket1, $ticket2, 'different secrets give different tickets';

dies_ok { $Class->new->ticket }
	'cannot make ticket without an id';
	
is $o->cookie_name, "Discuss::Apache::Auth::Ticket", 'cookie name';

my $new = $Class->new($r);
$r->{headers_in} = {};
throws_ok {$new->fetch_cookie} 'Discuss::Exception::NoAuthTicket',
	'no ticket cookie';


sub fake_cookie {
	my ($auth_object, $cookie_value) = @_;
	my $cookie = CGI::Cookie->new(
		'-path' => '/',
		'-expires' =>  '+12M',
		'-name' => $auth_object->cookie_name,
		'-value' => $cookie_value,
	);
	$auth_object->{request}->{headers_in} 
		= {"Cookie" => $cookie->as_string };
};

fake_cookie($new, 'illegal');
throws_ok {$new->fetch_cookie} 'Discuss::Exception::BadAuthTicket', 
	'illegal ticket cookie format';
SKIP: {
	skip "no exception" => 2 unless $@;
	my $e = $@;
	is $e->name, $new->cookie_name, 'exception cookie name set';
	is $e->value, 'illegal', 'exception cookie value set';
};

fake_cookie($new, '12:12345');
throws_ok {$new->fetch_cookie} 'Discuss::Exception::BadAuthTicket', 
	'invalid ticket cookie';
SKIP: {
	skip "no exception" => 2 unless $@;
	my $e = $@;
	is $e->name, $new->cookie_name, 'exception cookie name set';
	is $e->value, '12:12345', 'exception cookie value set';
};
is $Class->handler($r), FORBIDDEN, 'handler returns forbidden on failure';

fake_cookie($new, $Class->new($r)->id(42)->ticket);
lives_ok { $new->fetch_cookie } 'valid cookie';
is $new->id, 42, 'id set after validation';
is $Class->handler($r), OK, 'handler returns ok on success';

isa_ok $new->clear_cookie, $Class;
ok( !CGI::Cookie->parse($r->{header_out}->{'Set-Cookie'})
		->{$new->cookie_name}->value,
	'cookie value cleared' );

$new->set_cookie;
like(CGI::Cookie->parse($r->{header_out}->{'Set-Cookie'})->{$new->cookie_name}->value, qr/^42:/, 
	'cookie value set');

{
	local $TODO = 'things to think about';
	fail("need to make cookie skip www/discuss part of domain");
	fail("need to cope with P5P");
};