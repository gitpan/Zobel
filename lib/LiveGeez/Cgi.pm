package LiveGeez::Cgi;
use base qw(Exporter);

BEGIN
{
	use strict;
	use vars qw($VERSION $EMAILMESSAGE $ZOBEL_VERSION);

	$VERSION = '0.14';
	$ZOBEL_VERSION = '0.14';

	require 5.000;

	use LiveGeez::Local;
	unless ( $useApache ) {
		require "$cgiDir/cgi-lib.pl";
	}
	else {
		use Apache;
	}

	$EMAILMESSAGE =<<END;
<p>If you think that you have reached this message in error please report
to <a href="mailto:$adminEmail?Subject=%%subject%%">$adminEmail</a></p>
END
}


sub print
{
my $self = shift;


	if ( $self->{apache} ) {
		$self->{apache}->print ( @_ );
	}
	else {
		print @_;
	}

}


sub TopHtml
{
my ( $self, $title, $bgcolor ) = @_;
$bgcolor ||= $defaultBGColor;

  return <<END_OF_TEXT;
<html>
<head>
<title>$title</title>
</head>
<body BGCOLOR="$bgcolor">
END_OF_TEXT

}


sub BotHtml
{
my $self = shift;

	"</body>\n</html>\n";
}


sub ParseCgi
{
my $self = shift;

	unless ( $self->{CgiParsed} ) {
		$self->{CgiParsed} = "true";
		if ( $self->{apache} ) {
			%{$_[0]} = $self->{apache}->args;
		}
		else {
			ReadParse ( $_[0] );
		}
	}
	$self->ParseCookie unless ( $self->{cookieParsed} );
}


sub HeaderPrint
{
my $self = shift;

	unless ( $self->{HeaderPrinted} ) {
		$self->{HeaderPrinted} = "true";
		if ( $self->{apache} ) {
			$self->{apache}->content_type('text/html');
			$self->{apache}->content_encoding('x-gzip')
				if ( $self->{'x-gzip'} );
			$self->{apache}->send_http_header;
		}
		else {
			print "Content-type: text/html\n";
			if ( $self->{'x-gzip'} ) {
				print "Content-Encoding:  x-gzip\n\n";
			}
			else {
				print "\n";
			}
		}
	}
}


sub DieCgi
{
my $self = shift;

	$self->{'x-gzip'} = 0;
	$self->HeaderPrint;
	if ( $self->{apache} ) {
		$self->{apache}->print ( "<h1>An Error Was Encountered:</h1>\n" );
		$self->{apache}->print ( "<h1>$_[0]</h1>\n" );
	}
	else {
		CgiError ( $_[0] );
	}
	$self->print ( "<hr><p align=right><a href=\"http://libeth.netpedia.net/Zobel/\"><i>Zobel $ZOBEL_VERSION</i></a></p>" );
	if ( $self->{apache} ) {
		# $self->{apache}->exit(0); 
		# Apache::exit(DONE);
		$self->{apache}->exit(); 
	}
	else {
		exit (0);
	}
}



sub DieCgiWithEMail
{
	my $message = $EMAILMESSAGE;
	$message =~ s/%%subject%%/$_[2]/;
	DieCgi ( $_[0], $_[1].$message );
}



sub ParseCookie
{
my $self = shift;
# cookies are seperated by a semicolon and a space
my ( @rawCookies ) = split ( /; /, $ENV{'HTTP_COOKIE'} );


	foreach ( @rawCookies ) {
    	if ( /prefs/ ) {
 		($prefs, $key1, $val1, $key2, $val2, $key3, $val3, $key4, $val4) = split ( /[=&]/, $_ );
    	   	$self->{"cookie-$key1"} = $val1;                      # system
    	   	$self->{"cookie-$key2"} = $val2;                      # frames
    	   	$self->{"cookie-$key3"} = ($key3) ? $val3 : "false";  # 7-bit
    	   	$self->{"cookie-$key4"} = ($key4) ? $val4 : $defaultLang;  # lang
       	}
	} 

	$self->{cookiedParsed} = "true";
	1;
} 

 
sub SetCookie
{
my ( $self, $encoding, $frames, $bit7, $lang ) = @_;
my $path;


	$frames  = "no"         unless ( $frames );
	$bit7    = "false"      unless ( $bit7 );
	$lang    = $defaultLang unless ( $lang );
 
	$prefs   = "geezsys=$encoding&frames=$frames&7-bit=$bit7&lang=$lang";
	$path    = "/"; 

	"Set-Cookie: prefs=$prefs; expires=$cookieExpires; path=$path; domain=$cookieDomain\n";

}
#########################################################
# Do not change this, Do not put anything below this.
# File must return "true" value at termination
1;
##########################################################


__END__


=head1 NAME

LiveGeez::Request - Parse a LiveGe'ez CGI Query

=head1 SYNOPSIS

 use LiveGeez::Request;
 use LiveGeez::Services;

 main:
 {

 	my $r = LiveGeez::Request->new;

	ProcessRequest ( $r ) || $r->DieCgi ( "Unrecognized Request." );

	exit (0);

 }

=head1 DESCRIPTION

Request.pm instantiates an object that contains a parsed LiveGe'ez query.
Upon instantiation the environment is checked for CGI info and cookie data
is read and used.  This does B<NOT> happen if a populated hash table is
passed (in which case the hash data is applied) or if "0" is passed as an
arguement.
The request object is required by any other LiveGe'ez function of object.

=head1 AUTHOR

Daniel Yacob,  L<LibEth@EthiopiaOnline.Net|mailto:LibEth@EthiopiaOnline.Net>

=head1 SEE ALSO

S<perl(1).  Ethiopic(3).  L<http://libeth.netpedia.net/LiveGeez.html|http://libeth.netpedia.net/LiveGeez.html>>

=cut
