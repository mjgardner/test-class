use strict;
use warnings;

{   package Test::Foo;
    use parent qw( Test::Class );
    use Test::More;

    sub setup : Test(setup => 1) {
        pass("setup");
    }
    
    sub test :Test {
        pass();
    }
    
}

Test::Class->runtests();
