#! /usr/bin/perl

package Discuss::Exceptions;
use base qw(Exporter);
use strict;
use warnings;

our $VERSION = '0.21';

sub alias_name {
	my $class = shift;
	return unless $class =~ s/Discuss::Exception:://s;
	$class =~ s/([a-z])([A-Z])/\L$1_$2/gs;
	return lc "throw_$class";
}; 

my $Base_class;
my %Exceptions;
BEGIN {

	$Base_class = 'Discuss::Exception';

	my @Exceptions = qw( DBI BannedUser TemplateError Duplicate
		NoSuchObject BoardNotLive CannotPost InvalidEmail
		NoCurrentPost NoAuthTicket BadAuthTicket );

	for my $exception (@Exceptions) {
		my $class = "${Base_class}::${exception}";
		$Exceptions{$class}->{isa} = $Base_class;
		$Exceptions{$class}->{alias} = alias_name($class);
	};
	
	$Exceptions{'Discuss::Exception::NoSuchObject'}->{fields}
		= [ 'class', 'key' ];

	$Exceptions{'Discuss::Exception::Duplicate'}->{fields}
		= [ 'column', 'value' ];

	$Exceptions{'Discuss::Exception::BadAuthTicket'}->{fields}
		= [ 'name', 'value' ];

	$Exceptions{'Discuss::Exception::TemplateError'}->{fields}
		= [ 'template' ];

};

use Exception::Class $Base_class, %Exceptions;

our @EXPORT_OK
	= ('alias_name', map ($Exceptions{$_}->{alias}, keys %Exceptions) );

{
	package Discuss::Exception;
	
	sub full_message {
		my $self = shift;
		my $class = ref($self);
		my ($file, $line) = ($self->file, $self->line);
		my @fields = map {
			my ($key, $value) = ($_, $self->$_);
			defined($value) && $value ne '' ? ("$key => '$value'") : ();
		} sort ('error', @{$Exceptions{$class}->{fields} || []});
		my $fields = @fields ? " (" . join(', ', @fields) . ")" : "";
		"$class$fields at $file line $line\n";
	};
};

1;
