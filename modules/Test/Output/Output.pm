#! /usr/bin/perl -w

package Test::Output;
use 5.005;
use strict;
use Sub::Uplevel;
use Test::Builder;
use IO::File;
use Fcntl;
use Symbol qw(qualify_to_ref gensym);
use base qw(Exporter);


use vars qw($VERSION @EXPORT);
$VERSION = '0.01';
@EXPORT = qw(output_is output_isnt output_like output_unlike);


sub _try_as_caller {
	my ($sub, $level) = @_;
	eval { uplevel $level, $sub };
	return $@;
};


my $Last_output;

sub _get_output {
	my ($code, $fh, $level) = @_;
	$fh = qualify_to_ref($fh, caller);
	my $tmp = IO::File->new_tmpfile or die "no tmp file ($!)";
	my $old = gensym;
	*$old = *$fh;
	local *$fh = $tmp;
	my $exception = _try_as_caller($code, $level);
	*$fh = *$old;
	die if $exception;
	seek $tmp, SEEK_SET, 0 or die "could not seek ($!)";
	my $output = '';
	my $n;
	while ($n = read $tmp, $output, 1024, length($output)) {};
	die "could not read ($!)" unless defined($n);
	return($Last_output = $output);
};


sub _test_output {
	my ($method, $code, $expected, $fh, $name) = @_;
	my $builder = Test::Builder->new;
	my $todo = $builder->exported_to;
	local $Test::Builder::Level = 2;
	$builder->$method(_get_output($code, $fh, 6), $expected, $name);
};


sub output_is		(&$*;$) { _test_output('is_eq',	 @_) };
sub output_isnt		(&$*;$) { _test_output('isnt_eq',@_) };
sub output_like		(&$*;$) { _test_output('like',	 @_) };
sub output_unlike	(&$*;$) { _test_output('unlike', @_) };


sub last { $Last_output };

1;
