#! /usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';
use Test::Exception;
use File::Basename;

BEGIN { use_ok( 'Discuss::Exceptions' ) };
BEGIN { use_ok( 'Discuss::Exceptions', @Discuss::Exceptions::EXPORT_OK ) };

is alias_name('Discuss::Exception::InvalidEmail'),
	'throw_invalid_email', 'alias name of an exception';

is alias_name('Discuss::Exception::DBI'),
	'throw_dbi', 'alias name of an all caps exception';

ok !alias_name('x'), 'bad alias name';

eval { Discuss::Exception::DBI->throw };
like $@, qr!^Discuss::Exception::DBI at .*?exception.t line \d+\n$!s,
	"stringification without message";

eval { Discuss::Exception::TemplateError->throw(error => 'x', template => 'y') };
like $@, qr!^\QDiscuss::Exception::TemplateError (error => 'x', template => 'y')\E at .*?exception.t line \d+\n$!s,
	"stringification with message";

my @Exceptions = qw(
	Discuss::Exception::DBI
	Discuss::Exception::BannedUser
	Discuss::Exception::TemplateError
	Discuss::Exception::Duplicate
	Discuss::Exception::NoSuchObject
	Discuss::Exception::BoardNotLive
	Discuss::Exception::CannotPost
	Discuss::Exception::InvalidEmail
	Discuss::Exception::NoCurrentPost
	Discuss::Exception::BadAuthTicket
	Discuss::Exception::NoAuthTicket
);

foreach my $class (@Exceptions) {
	throws_ok { $class->throw } $class;
	isa_ok $@, 'Discuss::Exception', $class;
	throws_ok {
		no strict 'refs';
		&{ alias_name($class) };
	} $class, "alias threw $class";

};

{
	throws_ok { throw_bad_auth_ticket name=>'foo', value=>'bar' }
		'Discuss::Exception::BadAuthTicket';
	my $e = $@;
	is( $e->name, 'foo', 'name set' );
	is( $e->value, 'bar', 'value set' );
}

{
	throws_ok { throw_no_such_object class=>'foo', key=>'bar' }
		'Discuss::Exception::NoSuchObject';
	my $e = $@;
	is( $e->class, 'foo', 'class set' );
	is( $e->key, 'bar', 'key set' );
}

{
	throws_ok { throw_template_error template=>'foo', error=>'bar' }
		'Discuss::Exception::TemplateError';
	my $e = $@;
	is( $e->template, 'foo', 'TemplateError class set' );
	is( $e->error, 'bar', 'TemplateError error set' );
}


{
	throws_ok { throw_duplicate column=>'foo', value=>'ni', error=>'bar' }
		'Discuss::Exception::Duplicate';
	my $e = $@;
	is( $e->column, 'foo', 'Duplicate key set' );
	is( $e->value, 'ni', 'Duplicate value set' );
	is( $e->error, 'bar', 'Duplicate error set' );
}