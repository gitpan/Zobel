#!/usr/bin/perl

use LiveGeez::Local;
use LiveGeez::Request;
use LiveGeez::Services;
use ENH;

main:
{
local ( %input ) = ();
local ( $r ) = LiveGeez::Request->new;


	if ( $ENV{PATH_INFO} ) {
		#
		#  If the URL is in the form http://www.us.com/X.pl/SYSTEM/
		#                         or http://www.us.com/X.pl/SYSTEM/index.html
		#
		#  we extract the SYSTEM and assume the default file is index.sera.html
		#  we process and exit.
		#

		my @fileString =  split ('/', $ENV{PATH_INFO});
		my $sys        =  $fileString[1];
		if ( $#fileString == 1 || $fileString[2] eq "index.html" ) {
			$input{file} = "/index.sera.html";
		}
		else {
			$input{file}  =  $ENV{PATH_INFO};
			$input{file}  =~ s/\/$sys//;
			$input{file} .=  "/index.sera.html"
				if ( $input{file} !~ /htm(l)?$/ );
		}
		$sys = "FirstTime"  if  ( ($sys =~ /image/i) || ($sys eq "ENHPFR") );
		$input{sysOut} = $sys;

	} else {
		ReadParse ( \%input );
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
	$input{file} = "/index.sera.html" if ( $input{file} =~ /(\/)?index.serax.html/ );

	$r->ParseInput ( \%input );
	undef ( %input );


	&SetCookie ( $r ) if ( $r->{setCookie} );


    if ( $r->{type} eq "file" ) {

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
		ProcessRequest ( $r ) || CgiDie ( "Unrecognized Request." );
    }

	exit (0);

}


sub SetCookie
{
local ( $r ) = shift;


	print "Content-type: text/html\n";
	if ( $r ) {
		$r->{HeaderPrinted} = "true";
		print  setCookie ( $r->{sysOut}->{sysName}, $r->{frames}, 
	                       $r->{sysOut}->{'7-bit'} );
	} elsif ( $0 =~ "NoFrames" ) {
		print setCookie ( $defaultSysOut, "no", "false" );
	} else {
		print setCookie ( $defaultSysOut, "yes", "false" );
	}

}


sub PrintKeys 
{
local ( *input ) = @_ if @_ == 1;
local ( %input ) = @_ if @_  > 1;
local ( $key );


	print PrintHeader;
	print HtmlTop ( "CGI Keys Received" );
	print "<h1 align=\"center\">CGI Keys Received:</h1>\n\n";

	print "<ul>\n";
    for $key ( keys %input ) {
      print "  <li><b>$key =\&gt; $input{$key}</b>\n";
    }
	print "</ul>\n";

    print HtmlBot ();

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
