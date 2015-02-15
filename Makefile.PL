use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Git::Repository::Plugin::LogNumstat',
    AUTHOR              => 'KUBO Koichi <k@obuk.org>',
    VERSION_FROM        => 'lib/Git/Repository/Plugin/LogNumstat.pm',
    ABSTRACT_FROM       => 'lib/Git/Repository/Plugin/LogNumstat.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'version'    => 0,
	'Test::Output' => 0,
	'Test::Git' => 0,
	'File::Copy' => 0,
	'File::Spec::Functions' => 0,
	'Git::Repository' => 0,
	'Git::Repository::Plugin::Log' => 0,
	'YAML' => 0,
	'Cwd' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Git-Repository-Plugin-LogNumstat-*' },
);
