use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Games::WordGuess',
    'VERSION_FROM' => 'WordGuess.pm', # finds $VERSION
);
