use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Test::Class',
    'VERSION_FROM'	=> 'Class.pm', # finds $VERSION
    'PREREQ_PM'		=> {
    	Attribute::Handlers		=> 0.77,
    	Class::ISA				=> 0.32,
    	IO::File				=> 1.08,
    	Storable				=> 2.04,
    	Test::Builder			=> 0.16,
    	Test::Builder::Tester	=> 0.09,
    	Test::Differences		=> 0.43,
    	Test::Exception			=> 0.10,
    	Test::More				=> 0.44,
    	Devel::Symdump			=> 2.03,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Class.pm', # retrieve abstract from module
       AUTHOR     => 'Adrian Howard <adrianh@quietstars.com>') : ()),
);
