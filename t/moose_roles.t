#! /usr/bin/perl -T
package main;

use strict;
use warnings;

use Test::More;

BEGIN {
    no warnings;
    eval "use Moose";
    if ($@ ) {
        plan skip_all => "need Moose" if $@;
    } else {
        plan tests => 21;
        use_ok 'Test::Class';
        use lib qw(t/test-libs/lib-moose);
        use_ok 'My::Test::Class';
        use_ok 'Moose::Meta::Class';
        use_ok 'Moose::Util';
    }
}

my $test = My::Test::Class->new;

Moose::Util::apply_all_roles($test,'My::Test::Class::Role');

eval {
    $test->runtests;
};

ok(!$@, "Eval should return cleanly with Moose::Role application");
ok(defined $test->method_info_called,"_method_info_called is defined");
ok($test->method_info_called > 0,"_method_info called count is correct");

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
ok(defined $test->method_info_called,"_method_info_called is defined");
ok($test->method_info_called > 0,"_method_info called count is correct");

done_testing();
