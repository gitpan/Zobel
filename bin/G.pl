#!/usr/bin/perl

use LiveGeez::Local;
use LiveGeez::Request;
use LiveGeez::Services;
use ENH;


sub SetCookie
{
local ( $r ) = shift;


	if ( $r ) {
		print $r->SetCookie ( $r->{sysOut}->{sysName}, $r->{frames}, 
							  $r->{sysOut}->{'7-bit'} );
	} elsif ( $0 =~ "NoFrames" ) {
		print $r->SetCookie ( $defaultSysOut, "no", "false" );
	} else {
		print $r->SetCookie ( $defaultSysOut, "yes", "false" );
	}

}


sub CheckBrowser
{
	my @browser = split(/ /, $ENV{HTTP_USER_AGENT});
	if ($browser[0]=~/Mozilla/) { 
		my @model      = split(/\//, $browser[0]);
		local $brand   = $model[0];	
		local $version = $model[1];
	}
    $wantFrames = ( (($version >= 2) && ($brand eq "Mozilla"))
					|| (($version >= 3) && ($browser[0] =~ /MSIE/)) )
				? $wantFrames = "yes"
				: $wantFrames = "no"
				;
}


main:
{
local ( %input ) = ();
local ( $r ) = LiveGeez::Request->new ( 0 ); # don't parse input


	if ( ($pathInfo = $ENV{PATH_INFO}) ) {
		#
		#  If the URL is in the form http://www.us.com/X.pl/SYSTEM/
		#                         or http://www.us.com/X.pl/SYSTEM/index.html
		#
		#  we extract the SYSTEM and assume the default file is index.sera.html
		#  we process and exit.
		#

		if ( $pathInfo =~ "/Selamta/" ) {
			$r->ParseCookie;
			$input{file}    = "/index.sera.html";
			$input{sysOut}  = ( $r->{'cookie-geezsys'} )
			                ? ( $r->{'cookie-geezsys'} )
			                : "FirstTime"
			                ;
			$input{'7-bit'} = ( $r->{'cookie-7-bit'} )
			                ? ( $r->{'cookie-7-bit'} )
			                : ( $ENV{HTTP_USER_AGENT} =~ /Mac/i )
			                  ? "true"
			                  : "false"
			                ;
			$input{frames}  = ( $r->{'cookie-frames'} )
			                ? ( $r->{'cookie-frames'} )
			                : CheckBrowser
			                ;
		} else {
			my @fileString    =  split ( '/', $pathInfo );
			my $sys           =  $fileString[1];
			if ( $#fileString == 1 || $fileString[2] eq "index.html" ) {
				$input{file}  = "/index.sera.html";
			}
			else {
				$input{file}  =  $pathInfo;
				$input{file}  =~ s/\/$sys//;
				$input{file} .=  "/index.sera.html"
					if ( $input{file} !~ /htm(l)?$/ );
			}
			$sys = "FirstTime"  if  ( ($sys =~ /image/i) || ($sys eq "ENHPFR") );
			$input{sysOut} = $sys;
		}

	} else {
		$r->ParseCgi ( \%input );
	}



	if ( $input{sysOut} =~ /image/i  || $input{sys} =~ /image/i
	     || $input{sysOut} eq "FirstTime" || $input{sys} eq "FirstTime" 
	     || $input{sysOut} eq "ENHPFR" || $input{sys} eq "ENHPFR" )
	{
		$input{sysOut} = $defaultSysOut;
		delete ( $input{sys} );
		$r->{FirstTime} = "true";
		$r->{setCookie} = "true";
	}

	$r->ParseQuery ( \%input );
	undef ( %input );


	SetCookie ( $r ) if ( $r->{setCookie} );


	if ( $r->{type} eq "file" ) {

		$r->HeaderPrint;

		$r->{isArticle} = "true" if ( $r->{file} =~ /[0-9]\.sera/ );
		if ( $0 =~ "NoFrames" ) {
			$r->{frames}     =  "no";
			$r->{scriptURL}  =~ s/G.pl/NoFrames.pl/;
			$r->{scriptBase} =~ s/G.pl/NoFrames.pl/;
		}
	    if ( $r->{isArticle} ) {
			if ( $r->{frames} eq "skip" ) {
				ProcessFramesFile ( $r );
			} elsif ( $r->{frames} eq "no" ) {
				ProcessNoFramesFile ( $r );
			} else {
				OpenFrameSet ( $r, "/misc/Frames/frame.html" );
			}
		} else {
			$r->{mainPage} = "true"
				if ( $r->{file} =~ m#^/index.sera.html# );
			ProcessFramesFile ( $r );
		}

    } else {
		ProcessRequest ( $r ) || $r->DieCgi ( "Unrecognized Request." );
    }

	exit (0);

}


__END__


=head1 NAME

ENH/Tobia Zobel -- Remote Processing of Ethiopic Web Pages

=head1 SYNOPSIS

http://www.xyz.com/G.pl?sys=MyFont&file=http://www.zyx.com/dir/file.html

or

% G.pl sys=MyFont file=http://www.zyx.com/dir/file.html

=head1 DESCRIPTION

G.pl is the ENH & Tobia front version of the Zobel default "Z.pl" script.
Requires the ENH.pm module found in the same directory G.pl is distributed
in.

=head1 AUTHOR

Daniel Yacob,  L<LibEth@EthiopiaOnline.Net|mailto:LibEth@EthiopiaOnline.Net>

=head1 SEE ALSO

S<perl(1).  LiveGeez(3).  Ethiopic(3).  L<http://libeth.netpedia.net|http://libeth.netpedia.net>>

=cut
