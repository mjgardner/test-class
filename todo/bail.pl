use strict;
use warnings;

{   package Test::Foo;
    use parent qw( Test::Class );
    use Test::More;

    sub setup : Test(startup) {
        my $self = shift;
        $self->BAIL_OUT("startup");
    }

    sub test :Test(99) {
        pass();
    }

}

Test::Foo->runtests();
