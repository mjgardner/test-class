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
    $self->method_info_called( ( $self->method_info_called || 0) + 1);
};

1;
