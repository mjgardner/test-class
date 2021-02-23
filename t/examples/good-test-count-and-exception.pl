package Test;

use Test::More;
plan tests => 1;

use parent qw( Test::Class );

sub mytest : Tests(2) {
    ok 1;
    ok 1;

    die 123123;
}

__PACKAGE__->new()->runtests();
