#!/usr/bin/perl

use LiveGeez::Local;
use LiveGeez::Request;
use LiveGeez::Services;

main:
{
local ( %input );
local ( $r ) = LiveGeez::Request->new;


	ReadParse ( \%input );
	$r->ParseInput ( \%input );
	undef ( %input );

	SetCookie ( $r ) if ( $r->{setCookie} eq "true" );

	ProcessRequest ( $r ) || CgiDie ( "Unrecognized Request." );

	exit (0);

}


sub
SetCookie
{
local ( $r ) = shift;


	print "Content-type: text/html\n";
	$r->{HeaderPrinted} = "true";
	print  setCookie ( $r->{sysOut}->{sysName}, $r->{frames}, 
	                   $r->{sysOut}->{'7-bit'} );
}


sub
PrintKeys 
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

Zobel -- Remote Processing of Ethiopic Web Pages

=head1 SYNOPSIS

http://www.xyz.com/Z.pl?sys=MyFont&file=http://www.zyx.com/dir/file.html

or

% Z.pl sys=MyFont file=http://www.zyx.com/dir/file.html

=head1 DESCRIPTION

Z.pl is the front end of the "Zobel" implementation of the LiveGe'ez Remote
Processing Protocol.  The expected and intended use is via CGI query,
however the Z.pl script is servicable at the command line as well.

=head1 AUTHOR

Daniel Yacob,  L<LibEth@EthiopiaOnline.Net|mailto:LibEth@EthiopiaOnline.Net>

=head1 SEE ALSO

S<perl(1).  LiveGeez(3).  Ethiopic(3).  L<http://libeth.netpedia.net|http://libeth.netpedia.net>>

=cut
