#! /usr/bin/perl

package Class::InsideOut;
use strict;
use warnings;
use Attribute::Handlers::Prospective;
use Scalar::Util ();
use NEXT;

our $VERSION = 0.04;

{
	no warnings;	
	*self_id = *Scalar::Util::refaddr;
};

my @Values;

#	no strict 'refs';
sub Field : ATTR {
	my ($class, $symbol, $hashref) = @_;
	my $name;
	if ($symbol =~ m/LEXICAL\(%(.*)\)/) {
		$name = $1;
	} elsif (ref($symbol)) {
		$name = *{$symbol}{NAME};
	} else {
		#die "panic: unknown symbol type $symbol";
	};
	push @Values, $hashref;
# 		*{"$class::$name"} = sub {
# 			my $id = shift->self_id;
# 			@_ ? $hashref->{$id} = shift : $hashref->{$id};
# 		};
};

sub DESTROY {
	my $id = $_[0]->self_id;
	delete $_->{$id} foreach @Values;
	$_[0]->NEXT::DESTROY()
};

1;