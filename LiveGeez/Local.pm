package LiveGeez::Local;

require 5.000;
require Exporter;

@ISA = qw(Exporter);
@EXPORT = qw(
			ReadParse
			PrintHeader
			HtmlTop
			HtmlBot
			CgiDie

			$webRoot
			$cgiDir
			$scriptBase
			$scriptURL
			$URLCacheDir
			$FileCacheDir
			$defaultLang
			$defaultSysIn
			$defaultSysOut
			$iPath
			);


	$webRoot       = "/home2/enh/HTML";
	$cgiDir        = "/home2/enh/HTML/cgi";
	$scriptURL     = "http://enh.ethiopiaonline.net/G.pl";
	$scriptBase    = "/G.pl";
	$URLCacheDir   = "./cache";
	$FileCacheDir  = "./cache";
	$defaultLang   = "amh";   # amharic
	$defaultSysIn  = "sera";
	$defaultSysOut = "GFZemen";
	$iPath         = "/f";

require "$cgiDir/cgi-lib.pl";

$| = 1;


#########################################################
# Do not change this, Do not put anything below this.
# File must return "true" value at termination
1;
##########################################################


__END__


=head1 NAME

Local - Site Specific Settings for Your LiveGe'ez Installation

=head1 SYNOPSIS

use LiveGeez::Local;

=head1 DESCRIPTION

Local.pm is a required module by all other LiveGe'ez modules.  Local.pm
contains site specific settings for default encoding systems, language,
and paths.

=head1 AUTHOR

Daniel Yacob,  L<LibEth@EthiopiaOnline.Net|mailto:LibEth@EthiopiaOnline.Net>

=head1 SEE ALSO

S<perl(1).  Ethiopic(3).  L<http://libeth.netpedia.net/LiveGeez.html|http://libeth.netpedia.net/LiveGeez.html>>

=cut
