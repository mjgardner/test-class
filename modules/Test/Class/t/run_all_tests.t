#! /usr/bin/perl -Tw

use strict;
use Test::Class;

my @CALLED = ();

package Base::Test;
use base qw(Test::Class);
sub setup : Test(1) { die "this should not run" };

package A::Test;
use base qw(Base::Test);
sub setup : Test(1) {
	shift->builder->ok(1, "A::Test ran"); 
	push @CALLED, 'A::Test';
};

package B::Test;
use base qw(Base::Test);
sub setup : Test(1) { die "this should not run" };

package C::Test;
use base qw(B::Test);
sub setup : Test(1) {
	shift->builder->ok(1, "C::Test ran"); 
	push @CALLED, 'C::Test';
};


package main;
use Test::More tests => 14;

ok(! Base::Test->autorun,	'Base::Test->autorun default' );
ok(  A::Test->autorun,		'Base::Test->autorun default' );
ok(! B::Test->autorun,		'Base::Test->autorun default' );
ok(  C::Test->autorun,		'Base::Test->autorun default' );

is_deeply(
	[sort Test::Class->run_all_classes], [qw(A::Test C::Test)], 
	'run_all_classes found autorun classes'
);

A::Test->autorun(0);
ok(! A::Test->autorun, 'Base::Test->autorun switched off' );
B::Test->autorun(1);
ok(  B::Test->autorun, 'Base::Test->autorun switched on' );

is_deeply(
	[sort Test::Class->run_all_classes], [qw(B::Test C::Test)], 
	'run_all_classes found revised autorun classes'
);

A::Test->autorun(undef);
ok(  A::Test->autorun, 'Base::Test->autorun default returned' );
B::Test->autorun(undef);
ok(! B::Test->autorun, 'Base::Test->autorun default returned' );

is_deeply(
	[sort Test::Class->run_all_classes], [qw(A::Test C::Test)], 
	'run_all_classes found default autorun classes again'
);

Base::Test->runtests;
is_deeply(
	[sort @CALLED], [qw(A::Test C::Test)], 
	'runtests ran default autorun classes'
);
