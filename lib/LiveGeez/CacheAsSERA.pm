package LiveGeez::CacheAsSERA;
use base qw(HTML::Filter Exporter);

BEGIN
{
	use strict;
	use vars qw($VERSION @EXPORT_OK @gFile @FontStack %SystemList);

	$VERSION = '0.14';

	@EXPORT_OK = qw(HTML);

	use LiveGeez::Local;
	use LiveGeez::Services;
	require Convert::Ethiopic::System;
	require HTML::Entities;

	$#gFile = 100;
	$#FontStack = 4;
}


sub output
{
my $self = shift;


	$_ = shift;

	if ( ${$FontStack[ $self->{fontStack} ]{sysIn}} ) {
		NEXT:
		if ( m|<(/)?font|i ) {  # a font tag
			s/<font([^>]+)>/$self->UpdateFontTag($1)/oei;
			s/<\/font>//i if ( ${$FontStack[ $self->{fontStack} ]{delete}} );
		}
		elsif ( m|<(/)?span|i ) {  # a span tag
			s/<span([^>]+)>/$self->UpdateSpanTag($1)/oei;
			s/<\/span>//i if ( ${$FontStack[ $self->{fontStack} ]{delete}} );
		}
		elsif ( m|<td|i ) {  # a span tag
			s/<td([^>]+)>/$self->UpdateSpanTag($1)/oei;
			s/<span/<td/;
		}
		elsif ( !/[<>]|(^(\s+)$)/o ) { # not a tag or empty space
			$self->{request}->{sysIn}  = ${$FontStack [ $self->{fontStack} ]{sysIn}};
			$self->{request}->{string} = &decode_more_entities(HTML::Entities::decode($_));
			$_ = "<sera>" . ProcessString ( $self->{request} ) . "</sera>";
		}
		elsif ( />./ ) {      # very rare, I hope... some software seems to
		                      # like " ?> " to close images.  This could be
		                      # an HTML::Parser error
			my $trash;
			( $trash, $_ ) = split (/>/);
			push ( @gFile, "$trash>" );
			goto NEXT;
		}
	}

	push ( @gFile, $_ );


}


sub start
{
my $self = shift;


	if ( $_[0] eq "font" ) {
		$FontStack[ ++$self->{fontStack} ]{sysIn} = &GetSystemOut ( $self, $_[1]{face} );
	}
	elsif ( $_[0] eq "span" || $_[0] eq "td" ) {
		$_[1]{style} =~ /font-family:\s*(['"]|(&quot;))?([\w -]+)[;'"&]?/i;
		$FontStack[ ++$self->{fontStack} ]{sysIn} = ( $3 ) ? &GetSystemOut ( $self, $3 ) : undef;
	}

	$self->SUPER::start(@_);

}  


sub end
{
my $self = shift;


	$self->SUPER::end(@_);
	$self->{fontStack}-- if ( $_[0] eq "font" || $_[0] eq "span" || $_[0] eq "td" );

}


sub UpdateFontTag
{
my ( $self, $args ) = ( shift, shift );


	if ( ($args !~ /size/i) && ($args !~ /color/i) ) {
		${$FontStack[ $self->{fontStack} ]{delete}} = "true";
		return ( "" );
	}

	$args =~ s/(\s*)?face(\s*)=(\s*)"?([^"]+)"?//i;

	"<font$args>";

}


sub UpdateSpanTag
{
my ( $self, $args ) = ( shift, shift );


	#
	# if ( ($args !~ /font-size/i) && ($args !~ /font-color/i) ) {
	#
	if ( $args !~ ";" || $args =~ "char-type:" ) {
		${$FontStack[ $self->{fontStack} ]{delete}} = "true";
		return ( "" );
	}

	# $args =~ s/(\s*)?((\w+-)*)?font-family:\s*(['"]|&quot;)?(.*?);+?//gi;
	#
	#  This takes care of font names with boundaries:
	#
	$args =~ s/(\s*)?((\w+-)*)?font-family:\s*(['"]|&quot;)(.*?)$1//gi;
	#
	#  This takes care of font names without boundaries:
	#
	$args =~ s/(\s*)?((\w+-)*)?font-family:\s*[\w -]+//gi;

	"<span$args>";

}


sub GetSystemOut
{
my ( $self, $face )  = ( shift, shift );


	if ( !$face ) {
		if ( $self->{fontStack} && ${$FontStack[ $self->{fontStack} ]{sysIn}} )
	 	{
			$face = $lastFace;
		}
		else {
			return ( undef );
		}
	}
	$lastFace = $face;

	$SystemList{$face} ||= new Convert::Ethiopic::System ( $face );

	\$SystemList{$face};  # Return the pointer

}


sub UpdateHREF
{
my ($file, $args) = @_;


	$args =~ s|"\./|| if ( $file->{isRemote} );

	#
	#  if LIVEGEEZLINK is already here, don't add it
	#
	return ( $args ) if ( $args =~ "LIVEGEEZLINK" );

	#
	#  else, add it
	#
	"$args LIVEGEEZLINK";

}


sub HTML
{
my ( $file, $sourceFile ) = ( shift, shift );
my $p = new LiveGeez::CacheAsSERA;
my $seraFile = $sourceFile;


	$seraFile =~ s/\.htm(l)?(\.gz)?/.sera.html/i;
	$seraFile =~ s/$webRoot/$FileCacheDir/
		unless ( $sourceFile =~ "cache" );
	$file->{isZipped} = "true";
	$file->{request}->{sysIn} = new Convert::Ethiopic::System ( "sera" );

	return ( "$seraFile.gz" ) if (-e "$seraFile.gz");

	$p->{request}->{sysOut} = new Convert::Ethiopic::System ( "sera" );
	$p->{request}->{sysOut}->{langNum} = $file->{request}->{sysOut}->{langNum};
	$p->{request}->{sysOut}->{options} = $file->{request}->{sysOut}->{options};

	system ( 'gzip', '-d', $sourceFile ) if ( $sourceFile =~ s/\.gz$// );

	$p->parse_file( $sourceFile );
	open ( SERACACHE, ">$seraFile" ) || $file->{request}->DieCgi
		 ( "!: Could Not Open Source File: $seraFile!\n" );

	$_ = join ( "", @gFile );
	$#gFile = -1;
	#
	# strip extra <sera> and </sera> tags
	#
	s#</sera>(<((br)|((/)?(p)))>)?<sera>#$1#og;
	s#<sera>&nbsp;</sera>#&nbsp;#g;

	#
	# set up local links with Ethiopic text to use Zobel
	#
	my ($space, $link, $data);
	s#<a(\s+)(href[^>]+)>(.*?)</a>#$space = $1; $arg = $2; $data = $3; $link = ($3 =~ "<sera>" && $arg !~ $scriptBase && $arg !~ /mailto:/i) ? UpdateHREF($file, $arg) : $arg ; "<a$space$link>$data</a>"#oeisg;
	s/<META([^>]+)>(\r)?(\n)?//ig;

	#
	# strip out anything before the <html declaration or
	# libeth gets confused with the tokens
	#
	s/(.*?)(<HTML)/$2/si;

	print SERACACHE;
	close ( SERACACHE );

	system ( 'gzip' , $seraFile );
	$seraFile .= ".gz";             # this is the return value

}


%entity2char		=(
	'sbquo'		=>	"\x82",
	'bdquo'		=>	"\x84",
	'hellip'	=>	"\x85",
	'dagger'	=>	"\x86",
	'Dagger'	=>	"\x87",
	'permil'	=>	"\x89",
	'circ'		=>	"\x88",
	'Scaron'	=>	"\x8a",
	'lsaquo'	=>	"\x8b",
	'OElig'		=>	"\x8c",
	'lsquo'		=>	"\x91",
	'rsquo'		=>	"\x92",
	'ldquo'		=>	"\x93",
	'rdquo'		=>	"\x94",
	'bull'		=>	"\x95",
 	'ndash'		=>	"\x96",
 	'mdash'		=>	"\x97",
	'tilde'		=>	"\x98",
	'trade'		=>	"\x99",
	'scaron'	=>	"\x9a",
	'rsaquo'	=>	"\x9b",
	'oelig'		=>	"\x9c",
	'Yuml'		=>	"\x9f"
);


sub decode_more_entities
{
my $array;


	if (defined wantarray) {
		$array = [@_]; # copy
	}
	else {
		$array = \@_;  # modify in-place
	}
	for (@$array) {
		s/(&(\w+);?)/$entity2char{$2} || $1/eg;
	}

	$array->[0];
}
#########################################################
# Do not change this, Do not put anything below this.
# File must return "true" value at termination
1;
##########################################################


__END__


=head1 NAME

LiveGeez::CacheAsSERA - HTML Conversion for LiveGe'ez 

=head1 SYNOPSIS

$cacheFile = LiveGeez::CacheAsSERA::HTML($f, $sourceFile)

Where $f is a File.pm object and $sourceFile is the pre-cached file name.

=head1 DESCRIPTION

CacheAsSERA.pm contains the routines for conversion of HTML document content
from Ethiopic encoding systems into SERA for document caching and later
conversion into other Ethiopic systems.

=head1 AUTHOR

Daniel Yacob,  L<LibEth@EthiopiaOnline.Net|mailto:LibEth@EthiopiaOnline.Net>

=head1 SEE ALSO

S<perl(1).  Ethiopic(3).  L<http://libeth.netpedia.net/LiveGeez.html|http://libeth.netpedia.net/LiveGeez.html>>

=cut