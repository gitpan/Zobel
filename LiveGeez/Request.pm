package LiveGeez::Request;

require 5.000;
require Exporter;

@ISA = qw(Exporter);
@EXPORT = qw(
			ReadParse
			CgiDie
			setCookie
			);

use Convert::Ethiopic::System;
use LiveGeez::Local;
require "$cgiDir/cookies.pl";


sub new
{
	my $class = shift;   # Without declaring a class and blessing
    bless {}, $class;    # inheritance doesn't happen
}


sub show
{
my ( $self ) = shift;

	foreach $key (sort keys %$self) {
		print "  $key  = $self->{$key}\n";
	}

}


sub Pragma
{
my ( $self ) = shift;
local ( *input ) = @_ if @_ == 1;
local ( %input ) = @_ if @_  > 1;
local ( $pragma, $key );


	# Look for pragma directives and group them together as a
	# comma deliminated list.  Pragmi might be passed as "pragma",
	# "pragma1", "pragma2", etc.

    for $key ( keys %input ) {
		$pragma .= "$input{$key}," if ($key =~ /pragma/i);
    }

	# if we found any pragma directives chop off the last comma 
	# and copy the complete list back into the %input hash.

	chop ( $self->{pragma} = lc ($pragma) ) if ( $pragma );

	# since I can never remember if there is a minus or not
	# lets do a little spell checking.

    $self->{pragma}             =~ s/7bit/7-bit/ig if ( $pragma );

	$self->{phrase}             = "true" if ( $self->{pragma} =~ /phrase/     );
	$self->{'no-cache'}         = "true" if ( $self->{pragma} =~ /no-cache/   );
	$self->{'date-only'}        = "true" if ( $self->{pragma} =~ /date-only/  );
	$self->{'is-holiday'}       = "true" if ( $self->{pragma} =~ /is-holiday/ );


}



sub SysOut
{
my ( $self ) = shift;
local ( *input ) = @_ if @_ == 1;
local ( %input ) = @_ if @_  > 1;


	if ( !$input{sysOut} ) {
		%cookies = &getCookies();
		$input{sysOut} = ( $cookies{geezsys} ) ? $cookies{geezsys} : $defaultSysOut;
	} 
	elsif ( $input{sysOut} =~ /\./ ) {
	 	my ($A,$B) = split ( /\./, $input{sysOut} );
		$input{sysOut}  = $A;
		$input{xferOut} = $B if ( !$input{xferOut} );
	}

	$self->{sysOut}     =  Convert::Ethiopic::System->new( $input{sysOut} );


	#==========================================================================
	#
	#  May as well set the output font number while we're at it...
	#

	$self->{sysOut}->FontNum;


	#==========================================================================
	#
	#  Finally set extra encoding options
	#
	$self->{sysOut}->{'7-bit'}  = "true" if ( $self->{pragma} =~ /7-bit/      );

    $self->{sysOut}->{options}  = $noOps;

	$self->{sysOut}->{options} |= $debug
								  if ( $self->{pragma} =~ /debug/      );
	$self->{sysOut}->{options} |= $ethOnly
								  if ( $self->{pragma} =~ /ethOnly/    );
	$self->{sysOut}->{options} |= $qMark
								  if ( $self->{pragma} =~ /qMark/      );
	$self->{sysOut}->{options} |= $gSpace
								  if ( $self->{pragma} =~ /gSpace/     );
	$self->{sysOut}->{options} |= $ungeminate
								  if ( $self->{pragma} =~ /ungeminate/ );
	$self->{sysOut}->{options} |= $uppercase
								  if ( $self->{pragma} =~ /uppercase/  );

}


sub ParseInput
{
my ( $self ) = shift;
local ( *input ) = @_ if @_ == 1;
local ( %input ) = @_ if @_  > 1;
local ( $key, $pragma );



	#==========================================================================
	#
	# First we reduce the lexicon we are going to work with 
	# by eliminating synanyms.

	$input{sysOut}  = $input{sys}  if ( $input{sys}  && !$input{sysOut} );
	$input{xferOut} = $input{xfer} if ( $input{xfer} && !$input{xferOut} );


	#==========================================================================
	#
	# Parse Pragma since directives can also be nested in sysOut variables
	#

	$self->Pragma ( \%input );


	#==========================================================================
	#
	# Now to refine sysIn and sysOut and set defaults.
	#

	# $self->{sysIn} = "sera" if ( !$input{sysIn} && $input{file} =~ ".sera." );

	$self->{sysIn}   =  ( $input{sysIn} )
	                 ?  Convert::Ethiopic::System->new( $input{sysIn} )
	                 :  Convert::Ethiopic::System->new( $defaultSysIn )
	                 ;

	$self->SysOut ( \%input );


	#==========================================================================
	#
	#
	#

	$self->{sysOut}->SysXfer ( lc ( $input{xferOut} ) );
	$self->{sysIn}->SysXfer ( lc ( $input{xferIn} ) );


	#==========================================================================
	#
	# If the "image" type is requested and the image path is appended
	# as a transfer variant, cut off the path and assign it to our 
	# iPath variable.
	#

	$self->{sysOut}->{iPath}
					= ( $self->{sysOut}->{sysName} =~ /image/i
						&& $self->{sysOut}->{xfer} ) 
					? $self->{sysOut}->{xfer}
					: $iPath
					;


	#==========================================================================
	#
	# We are going to compactify our date information.  This simplifies
	# our API and makes working with the LIVEGEEZ markup "date" attribute
	# a little smoother.
	#

	$self->{date} = "$input{day},$input{month},$input{year}" if ( $input{day} );

	if ( $input{cal} ) {
		$self->{calIn} = $input{cal};
	}
	elsif ( $input{datesys} ) {				# here for backwards compatibility
		$self->{calIn} = $input{datesys};
	}
	elsif ( $self->{date} ) {
		$self->{calIn} = "euro";			# default when not specified
	}


	#==========================================================================
	#
	#  Set the Request Language.
	#

	$self->{sysOut}->{lang} = $defaultLang if ( !$input{lang} );
	$self->{sysOut}->LangNum;
	$self->{sysOut}->{LCInfo} 
	     = ( $self->{sysOut}->{sysName} ne "Transcription" ) ? $WITHUTF8 : 0 ;


	#==========================================================================
	#
	#  Miscellaneous
	#

	$self->{frames}     = $input{frames}    if ( $input{frames} );
	$self->{setCookie}  = $input{setCookie} if ( $input{setcookie} );
	$self->{scriptURL}  = $scriptURL;
	$self->{scriptBase} = $scriptBase;


	#==========================================================================
	#
	#  Finally lets ID the request type itself.
	#

	if ( $input{file} ) {
		$self->{type} =  "file";
		$self->{file} =  $input{file};
		$self->{file} =~ s/$webRoot\///;
	} elsif ( $self->{date} ) {
		$self->{type} = "calendar";
	} elsif ( $input{string} ) {
		$self->{type}   = "string";
		$self->{string} = $input{string};
	} elsif ( $input{number} ) {
		$self->{type}   = "number";
		$self->{number} = $input{number};
	} elsif ( $input{game} ) {
		$self->{type} = "game-$input{game}";
	} elsif ( $input{about} ) {
		$self->{type} = "about";
	}

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

 use LiveGeez::Local;
 use LiveGeez::Request;
 use LiveGeez::Services;

 main:
 {
 local ( %input );
 local ( $r ) = LiveGeez::Request->new;


	ReadParse ( \%input );
	$r->ParseInput ( \%input );
	ProcessRequest ( $r ) || CgiDie ( "Unrecognized Request." );

	exit (0);

 }

=head1 DESCRIPTION

Request.pm instantiates an object that contains a parsed LiveGe'ez query.
The request object is required by any other LiveGe'ez function of object.

=head1 AUTHOR

Daniel Yacob,  L<LibEth@EthiopiaOnline.Net|mailto:LibEth@EthiopiaOnline.Net>

=head1 SEE ALSO

S<perl(1).  Ethiopic(3).  L<http://libeth.netpedia.net/LiveGeez.html|http://libeth.netpedia.net/LiveGeez.html>>

=cut
