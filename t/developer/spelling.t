#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

my $aspell_path = eval q{
    use Test::Spelling; 
    use File::Which;
    which('aspell') || die 'no aspell'
};
plan skip_all => 'Optional Test::Spelling, File::Which and aspell program required to spellcheck POD' if $@;
set_spell_cmd("$aspell_path list");
add_stopwords( <DATA> );
all_pod_files_spelling_ok();

__DATA__
AnnoCPAN
CPAN
perlmonks
RSS
LICENCE
API
APIs
Bowden
Bricolage
Corion
JUNIT
JUnit
Jansson
Lindstrom
ORGANISING
STDOUT
SUnit
Startup
TestCase
TestRunner
TestSuite
Uenalan
XSLT
XUNIT
al
darwin
organise
refactored
refactoring
runtests
scepticism
startup
teardown
todo
xUnit
Aperghis
Carnahan
Cawley
Deifik
Hai
Ishigaki
Jochen
Jore
Jost
Kenichi
Kinyon
Kirkup
Krieger
Lanning
Mathieu
Pham
Sauve
Stenzel
Stosberg
Tramoni
ben
et
imacat
qa
Langworth
