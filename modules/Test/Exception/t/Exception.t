#! /usr/bin/perl -Tw

use strict;

use Test::Builder::Tester tests => 18;

BEGIN { 
	my $module = 'Test::Exception';
    eval "use $module";
	if ($@) {
		print "Bail out!: Cannot find $module in (@INC)\n";
		exit(255);
	};
};


{
	package Local::Error::Simple;
	sub new { return bless {}, shift };
};


{	
	package Local::Error::Test;
	use base qw(Local::Error::Simple);
};


{	
	package Local::Error::Overload;
	use base qw(Local::Error::Simple);
	use overload q{""} => sub { "overloaded" }, fallback => 1;
};


{	
	package Local::Error::NoFallback;
	use base qw(Local::Error::Simple);
	use overload q{""} => sub { "no fallback" };
};


my %Exception = map {m/([^:]+)$/; lc $1 => $_->new} qw(
	Local::Error::Simple 
	Local::Error::Test 
	Local::Error::Overload 
	Local::Error::NoFallback
);


sub error {
	my $type = shift;
	return(1) if $type eq "none";
	die "a normal die\n" if $type eq "die";
	die $Exception{$type} if exists $Exception{$type};
	warn "exiting: unrecognised error type $type\n";
	exit(1);
};


test_out("ok 1");
dies_ok { error("die") };
test_test("dies_ok: die");

test_out("not ok 1 - lived. oops");
test_fail(+1);
dies_ok { error("none") } "lived. oops";
test_test("dies_ok: normal exit detected");

test_out("ok 1 - lived");
lives_ok { 1 } "lived";
test_test("lives_ok: normal exit");

test_out("not ok 1");
test_fail(+2);
test_diag("died: a normal die");
lives_ok { error("die") };
test_test("lives_ok: die detected");

test_out("not ok 1");
test_fail(+2);
test_diag("died: Local::Error::Overload (overloaded)");
lives_ok { error("overload") };
test_test("lives_ok: die detected");

test_out("ok 1 - expecting normal die");
throws_ok { error("die") } '/normal/', 'expecting normal die';
test_test("throws_ok: regex match");

test_out("not ok 1 - should die");
test_fail(+3);
test_diag("expecting: /abnormal/");
test_diag("found: a normal die");
throws_ok { error("die") } '/abnormal/', 'should die';
test_test("throws_ok: regex bad match detected");

test_out("ok 1 - threw Local::Error::Simple");
throws_ok { error("simple") } "Local::Error::Simple";
test_test("throws_ok: identical exception class");

test_out("not ok 1 - threw Local::Error::Simple");
test_fail(+3);
test_diag("expecting: Local::Error::Simple");
test_diag("found: normal exit");
throws_ok { error("none") } "Local::Error::Simple";
test_test("throws_ok: exception on normal exit");

test_out("ok 1 - threw Local::Error::Simple");
throws_ok { error("test") } "Local::Error::Simple";
test_test("throws_ok: exception sub-class");

test_out("not ok 1 - threw Local::Error::Test");
test_fail(+3);
test_diag("expecting: Local::Error::Test");
test_diag("found: $Exception{simple}");
throws_ok { error("simple") } "Local::Error::Test";
test_test("throws_ok: bad sub-class match detected");

test_out("not ok 1 - threw Local::Error::Test");
test_fail(+3);
test_diag("expecting: Local::Error::Test");
test_diag("found: Local::Error::Overload (overloaded)");
throws_ok { error("overload") } "Local::Error::Test";
test_test("throws_ok: throws_ok found overloaded");

test_out("not ok 1 - threw Local::Error::Overload (overloaded)");
test_fail(+3);
test_diag("expecting: Local::Error::Overload (overloaded)");
test_diag("found: $Exception{test}");
throws_ok { error("test") } $Exception{overload};
test_test("throws_ok: throws_ok found overloaded");

my $e = Local::Error::Test->new("hello");
test_out("ok 1 - threw $e");
throws_ok { error("test") } $e;
test_test("throws_ok: class from object match");

test_out("ok 1 - normal exit");
throws_ok { error("none") } qr/^$/, "normal exit";
test_test("throws_ok: normal exit matched");

test_out("ok 1");
dies_ok { error("nofallback") };
test_test("dies_ok: overload without fallback");

test_out("not ok 1");
test_fail(+2);
test_diag("died: Local::Error::NoFallback (no fallback)");
lives_ok { error("nofallback") };
test_test("lives_ok: overload without fallback");

test_out("not ok 1 - threw Local::Error::Test");
test_fail(+3);
test_diag("expecting: Local::Error::Test");
test_diag("found: Local::Error::NoFallback (no fallback)");
throws_ok { error("nofallback") } "Local::Error::Test";
test_test("throws_ok: throws_ok overload without fallback");

