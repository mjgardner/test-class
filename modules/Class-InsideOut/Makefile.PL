use 5.006001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Class::InsideOut',
    'VERSION_FROM'	=> 'lib/Class/InsideOut.pm', # finds $VERSION
    'PREREQ_PM'		=> {
    	'Test::More'  =>  0,
    	'Scalar::Util'	=>	1.09,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
       (AUTHOR     => 'Adrian Howard <adrianh@quietstars.com>') : ()),
);
