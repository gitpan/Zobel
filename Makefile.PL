
use Config;

use ExtUtils::MakeMaker;

my $VERSION = '0.10';

sub MY::dist {
	package MY; # so that "SUPER" works right
	my $inherited = shift->SUPER::dist(@_);
	$inherited =~ s/old text/new text/;
	$inherited;
	}

WriteMakefile(
	NAME		=> 'LiveGeez',
	DISTNAME	=> 'Zobel',
	VERSION		=> $VERSION,
	dist		=> { COMPRESS => 'gzip -9f', SUFFIX => 'gz',
		POSTOP => 'mv $(DISTNAME)-$(VERSION).tar.gz ../' },
	);

