package Apache::Zobel;

use strict;
use Apache::Constants qw(:common REDIRECT);
use Apache::Request;
use Apache::URI;

use LiveGeez::Local;
use LiveGeez::Request;
use LiveGeez::Services;


sub SetCookie
{
my $r = shift;

	print $r->SetCookie ( $r->{sysOut}->{sysName}, $r->{frames}, 
	                      $r->{sysOut}->{'7-bit'}, $r->{sysOut}->{lang} );
}




sub handler
{
	my $ap = new Apache::Request ($_[0]);

	my $args = $ap->args;

	if ( $args ) {
		$args =~ s/\/$//;
		$args = "file=$args" unless ( $args =~ "=" );
		if ( $args =~ /&/ ) {
			my $first = $args;
			$first =~ s/^(.*?)\&(.*)$/$1/;
			$args = "file=$args" unless ( $first =~ "=" );
		}
		$ap->args ( $args );
	}
	else {
		my $uri  = $ap->uri;
		$uri =~ s/^\///;
		unless ( $uri ) {
			$ap->internal_redirect ( "/index.html" );
			return OK;
		}
		$uri = "file=$uri" unless ( $uri =~ "=" );
		$ap->args ( $uri );
	}


 	my $r = new LiveGeez::Request ( $_[0] );

	SetCookie ( $r ) if ( $r->{setCookie} eq "true" );

	ProcessRequest ( $r ) || $r->DieCgi ( "Unrecognized Request." );
	
	$r = undef;

	OK;
}
1;
