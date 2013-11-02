#! /usr/bin/perl -T

package My::Test::Class;

use base qw(Test::Class);

use Test::More;

sub test_1 :Test(2) {
    my $self = shift;

    ok(1);
    ok(1);
}

sub test_2 :Test(2) {
    my $self = shift;

    ok(1);
    ok(1);
}

package My::Test::Class::Role;

use Moose::Role;

has 'method_info_called' => (
    is => 'rw',
    isa => 'Int',
    default => 0,
);

after '_method_info' => sub {
    my $self = shift;
    $self->method_info_called($self->method_info_called+1);
};

package main;

use strict;
use warnings;

use Test::More tests => 15;

use Moose::Meta::Class;
use Moose::Util qw(apply_all_roles);

my $test = My::Test::Class->new;

apply_all_roles($test,'My::Test::Class::Role');

eval {
    $test->runtests;
};

ok(!$@, "Eval should return cleanly with Moose::Role application");
is($test->method_info_called,8,"_method_info called count is correct");

my $new_package = Moose::Meta::Class->create(
    'My::Test::Class::MethodCallCounts',
    superclasses => ['My::Test::Class'],
    roles => [
        'My::Test::Class::Role',
    ],
)->name;

isa_ok($new_package, 'My::Test::Class::MethodCallCounts');
isa_ok($new_package, 'My::Test::Class');
isa_ok($new_package, 'Test::Class');

eval {
    $new_package->runtests;
};

ok(!$@, "Eval should return cleanly with Moose::Role application");
is($test->method_info_called,8,"_method_info called count is correct");

done_testing();
