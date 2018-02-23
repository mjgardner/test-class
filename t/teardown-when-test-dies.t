use strict;
use warnings;

my $line;
{
    package TeardownWhenTestDies;
    use base qw(Test::Class);
    use Test::More;

    sub setup_that_runs : Test( setup => 1 ) { ok(1, "setup works"); }

    sub my_test_method : Tests {
        BEGIN { $line = __LINE__ } die "oops!";
    }

    sub teardown_that_runs : Test( teardown => 1 ) {
        ok(1, 'teardown is run');
    }
}

use Test::Builder::Tester tests => 1;

test_out("ok 1 - setup works\nnot ok 2 - my_test_method died (oops! at ${\ __FILE__ } line $line.)\nok 3 - teardown is run");
test_fail( +2 );
test_err( "#   (in TeardownWhenTestDies->my_test_method)" );
Test::Class->runtests;
test_test("exception in method, but teardown is still run");
