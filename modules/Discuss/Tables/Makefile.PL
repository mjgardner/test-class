use 5.006001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Discuss::Tables',
    'VERSION_FROM'	=> 'Tables.pm', # finds $VERSION
    'PREREQ_PM'		=> {
    
    }, # e.g., Module::Name => 1.1
);
