use 5.006001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Test::Declarative',
    'VERSION_FROM'	=> 'Declarative.pm', # finds $VERSION
    'PREREQ_PM'		=> {
    	Test::More  	=>  0.46,
    	Test::Builder	=>	0.16,
    	Set::CrossProduct	=> 1.4,
    	
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Declarative.pm', # retrieve abstract from module
       AUTHOR     => 'Adrian Howard <adrianh@quietstars.com>') : ()),
);
