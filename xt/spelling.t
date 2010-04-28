#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

## no critic
my $spell_checker = eval q{
    use Test::Spelling; 
    use File::Which;
    which('ispell') || die 'no spell checker'
};
## use critic

plan skip_all => 'Optional Test::Spelling, File::Which and aspell or ispell required to spellcheck POD' if $@;
set_spell_cmd("$spell_checker -l");
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
Adrian
BAILOUT
Beck's
Bjorn
Cantrell
Cozens
Emil
Ferrari
Frankel
Goddard
Ian
Johan
Murat
O'Neill
Sebastien
Smalltalk
Terrence
agianni
co
Curtis
gnarly
Dolan
Brandt
Hynek
Edwardson
Cosimo
Streppone