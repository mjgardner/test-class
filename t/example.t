package Example;
sub new { bless {}, shift};

package Mock::DBI; use base qw(Example);


package Object; use base qw(Example);
sub open {return(1)};
sub close {return(1)};
sub field1 {'foo'};
sub field2 {'bar'};
sub read_only { 1 };


package Base::Test; 
use base qw(Test::Class);
use Test::More;

sub invarient_ok {
	return(1);
};

#####

sub test_fields : Test {
	my $self = shift;
	is($self->{object}->field1, 'foo', 'field1 access ok');
};

sub make_fixture : Test(setup) {
	my $self = shift;
	$self->{object} = Object->new();
	$self->{dbh} = Mock::DBI->new(-type => normal);
};

sub test_open : Test {
	my $self = shift;
	my ($o, $dbh) = ($self->{object}, $self->{dbh});
	ok($o->open($dbh), "opened ok");
};

sub test_close : Test {
	my $self = shift;
	my ($o, $dbh) = ($self->{object}, $self->{dbh});
	$self->builder->ok($o->close($dbh), "closed ok");
};

package Object::Test; 
use base qw(Base::Test);
use Test::More;

sub test_objects : Test(no_plan) {
	my $self = shift;
	ok($_->open, "opened $_") foreach @{$self->{objects}};
};

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);
	$self->{num_objects} = @{$self->{objects}};
	$self->num_method_tests('test_objects', $self->{num_objects});
	return($self);
};

sub _darwin_only : Test(setup) {
	my $self = shift;
	$self->SKIP_ALL("darwin only") unless $^O eq "darwin";	
};

sub test_fields : Test(+1) {
	my $self = shift;
	$self->SUPER::test_fields;
	is($self->{object}->field2, 'bar', 'field2 access ok');
};

sub test_test_fields : Test {
	my $self = shift;
	is($self->total_num_tests('test_fields'), 2, 'total_num_tests');
};

sub test_invarient : Test(teardown => 1) {
	my $self = shift;
	my $m = $self->current_method;
	ok($self->invarient_ok, "class okay after $m");
};

sub show_running_order {
	my $class = shift;
	my @setup = $class->setup_methods;
	my @teardown = $class->teardown_methods;
	$class->builder->diag('running order...');
	foreach my $method ($class->test_methods) {
		$class->builder->diag("@setup $method @teardown");
	};
};

sub txt_files_readable : Test(no_plan) {
	my $self = shift;
	my @files = <*.txt>;
	$self->num_tests(scalar(@files));
	ok(-r $_, "$_ readable") foreach (@files);
};

package Special::Object::Test;
use base qw(Object::Test);
use Test::More;

sub test_objects : Test(+1) {
	my $self = shift;
	$self->SUPER::test_objects;
	my @bad_objects = grep {! $_->read_only} (@{$self->{objects}});
	ok(@bad_objects == 0, "all objects read only");
};


package main;
use Test::More;
my ($o1, $o2) = (Object->new) x 2;

my $to1 = Object::Test->new(objects => [$o1, $o2]);
my $to2 = Special::Object::Test->new(objects => [$o1, $o2]);

$to1->runtests;
$to2->runtests;
