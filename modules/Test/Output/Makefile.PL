use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Test::Output',
    'VERSION_FROM'	=> 'Output.pm', # finds $VERSION
    'PREREQ_PM'		=> {
		Fcntl			=> 1.03,
		IO::File		=> 1.08,
		Sub::Uplevel	=> 0.06,
		Symbol			=> 1.02,
		Test::Builder	=> 0.15,
		Test::More		=> 0.45,
    }, 
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (# ABSTRACT_FROM => 'Output.pm', # retrieve abstract from module
       AUTHOR     => 'Adrian Howard <adrianh@quietstars.com>') : ()),
);
