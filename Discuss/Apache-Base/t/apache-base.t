#! /usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';
use Test::Exception;

use Apache::FakeRequest;
use Apache::MyConfig;
use Apache::Constants qw(:common);
use Scalar::Util qw(refaddr);
use Cwd;
use File::Spec;

my $r = Apache::FakeRequest->new(
	document_root => getcwd(),
	filename => File::Spec->catfile(getcwd(), 't', 'test.tt2'),
	uri => 'http://localhost/board/123/topic/456/post/789',
	path_info => '/123/topic/456/post/789',
);

sub Apache::FakeRequest::log { $r };
sub Apache::FakeRequest::info { $r };

BEGIN { use_ok ( 'Discuss::Apache::Base' ) };

is(Discuss::Apache::Base->plugin_base, 'Discuss::Plugin::User', 
	'plugin base');

{
	no warnings;
	local *Template::new = sub { 0 };
	use warnings;
	throws_ok {Discuss::Apache::Base->template($r)} 
		'Discuss::Exception::TemplateError';
};

isa_ok my $t1 = Discuss::Apache::Base->template($r), 'Template', 't1';
isa_ok my $t2 = Discuss::Apache::Base->template($r), 'Template', 't2';
ok refaddr($t1) == refaddr($t2), 
	'not doing expensive template creation if plugin base identical';

{
	no warnings;
	local *Discuss::Apache::Base::plugin_base = sub { 'hello' };
	use warnings;
	isa_ok my $t3 = Discuss::Apache::Base->template($r), 'Template', 
		't2';
	ok(refaddr($t1) != refaddr($t3),
		'templates with differing plugin base different');
}

ok $Apache::MyConfig::Setup{PERL_METHOD_HANDLERS},
	'have method handlers';

{
	no warnings;
	local *Template::process = sub {
		my (undef, undef, $vars) = @_;
		return;
	};
	local $Template::ERROR = "failtest";
	use warnings;
	is(Discuss::Apache::Base->handler($r), SERVER_ERROR, 
		'bad process gives server error');
}

{
	my ($request, $escaped, $printed, $result);
	{
		no warnings;
		local *Template::process = sub { 
			my (undef, undef, $vars, $output) = @_;
			$request = $vars->{_request};
			$escaped = $Discuss::Base::Escape_html;
			$$output = 'output';
		};
		local *Apache::FakeRequest::print = sub {
			$printed = $_[1];
		};
		$result = Discuss::Apache::Base->handler($r);
	};
	ok( $escaped, 'HTML is escaped' );
	is( $printed, 'output', 'output printed' );
	is( $request, $r, 'request sent to template' );
	is( $result, OK, 'good process gives server okay')
			|| diag $r->log_reason;
}
