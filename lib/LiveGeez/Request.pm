package LiveGeez::Request;
use base qw(LiveGeez::Cgi);


BEGIN
{
	use strict;
	use vars qw($VERSION @ISA);

	$VERSION = '0.14';

	require 5.000;

	use LiveGeez::Local;
	if ( $useApache ) {
		require Apache::Request;
		push ( @ISA, "Apache::Request" );
	}
	require Convert::Ethiopic::System;
}


sub new
{
my $class = shift;
my $self  = {};

	my $blessing = bless $self, $class;

	$self->{apache} = ( $self->isa ("Apache::Request") ) 
	  ? $self->SUPER::new ( shift )
	  : 0
	;

	$self->ParseQuery ( @_ ) unless ( @_ == 1 && $_[0] == 0 );

	$blessing;
}


sub show
{
my $self = shift;

	foreach $key (sort keys %$self) {
		$self->print ( "  $key = $self->{$key}<br>\n" );
	}

}


sub ParseQuery
{
my $self = shift;
my ( $key, $pragma );
local %input = ( @_ ) 		#  We are passed something.
          ? ( ref $_[0] )       #  Was it a reference?
            ?  %{$_[0]}            # Yes. 
            : @_                   # No. 
          : ()		        #  We were not passed anything, so declare our own.
          ;


	#==========================================================================
	#
	# First parse input and cookie data unless of course we already have data

	unless ( scalar (%input) ) {
		$self->ParseCgi ( \%input );
	} else {
		$self->ParseCookie;
	}


	#==========================================================================
	#
	# Next we reduce the lexicon we are going to work with 
	# by eliminating synanyms.

	$input{sysOut}  = $input{sys}  if ( $input{sys}  && !$input{sysOut} );
	$input{xferOut} = $input{xfer} if ( $input{xfer} && !$input{xferOut} );


	#==========================================================================
	#
	# Parse Pragma since directives can also be nested in sysOut variables
	#

	$self->Pragma;


	#==========================================================================
	#
	# Now to define sysIn and sysOut and set defaults.
	#

	if ( $input{file} =~ "://" )  {  # A URL
		$self->{sysIn}  =  ( $input{sysIn} )
		                ?  Convert::Ethiopic::System->new( $input{sysIn} )
		                :  ( $input{file} =~ /.sera./i )
		                   ? Convert::Ethiopic::System->new( "sera" )
		                   : 0
		                   ;
	}
	else {
		$self->{sysIn} = ( $input{sysIn} )
		               ?  Convert::Ethiopic::System->new( $input{sysIn} )
		               :  Convert::Ethiopic::System->new( $defaultSysIn )
		               ;
	}
	$self->SysOut;


	#==========================================================================
	#
	#
	#

	$self->{sysOut}->SysXfer ( lc ( $input{xferOut} ) );
	$self->{sysIn}->SysXfer  ( lc ( $input{xferIn} ) ) if ( $self->{sysIn} );


	#==========================================================================
	#
	# If the "image" type is requested and the image path is appended
	# as a transfer variant, cut off the path and assign it to our 
	# iPath variable.
	#

	$self->{sysOut}->{iPath} = ( $self->{sysOut}->{sysName} =~ /image/i
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

	$input{calIn} = $input{cal} if ( $input{cal} );
	if ( $input{calIn} ) {
		$self->{calIn} = $input{calIn};
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

	$self->{sysOut}->{lang}
	= ( $input{lang} )
	  ? $input{lang}
	  : ( $self->{'cookie-lang'} )
	    ? $self->{'cookie-lang'}
	    : $defaultLang
	; 

	$self->{sysOut}->LangNum;
	$self->{sysOut}->{LCInfo} = ( $self->{sysOut}->{sysName} ne "Transcription" ) ? $Convert::Ethiopic::System::WITHUTF8 : 0 ;


	#==========================================================================
	#
	#  Miscellaneous
	#

	$self->{frames}     = $input{frames}    if ( $input{frames} );
	$self->{setCookie}  = $input{setcookie} if ( $input{setcookie} );
	$self->{scriptURL}  = $scriptURL;
	$self->{scriptBase} = $scriptBase;
	$self->{'x-gzip'}   = ( ( $self->{apache} && $self->{apache}->content_encoding eq "gzip" )
	                        || ( $ENV{HTTP_ACCEPT_ENCODING} =~ "gzip" && $ENV{HTTP_USER_AGENT} !~ "MSIE" )
	                      ) ? 1 : 0;



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

   	undef ( %input ) unless ( @_ );
	1;
}


sub Pragma
{
my $self = shift;
########################
#
#  We use the %input from ParseQuery which is dynamically scoped.
#  This works because we know that Pragma is not accessed by anyone else.
#
#  my ( *input ) = @_;  # We have passed _ONLY_ the reference
my ( $pragma, $key );


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

	# We don't want to propogate "no-cache" into new links:
	$self->{pragma} =~ s/no-cache(,)?//;

	1;
}


sub SysOut
{
my $self = shift;
########################
#
#  We use the %input from ParseQuery which is dynamically scoped.
#  This works because we know that SysOut is not accessed by anyone else.
#
# my ( *input ) = @_;  # We have passed _ONLY_ the reference


	#==========================================================================
	#
	#  Check Cookies for extra info each time a page is loaded.
	#  Don't get cookie data if we are setting a new cookie.
	#
	$input{sysOut} = ( !$input{setcookie} && $self->{'cookie-geezsys'} )
				   ? $self->{'cookie-geezsys'}
				   : $defaultSysOut
				 	 unless ( $input{sysOut} )  # we were passed an explicit
				   ;                                # and over-riding sysOut


	if ( $input{sysOut} =~ /\./ ) {
	 	my ($A,$B) = split ( /\./, $input{sysOut} );
		$input{sysOut}  = $A;
		$input{xferOut} = $B unless ( $input{xferOut} );
	}


	$self->DieCgi ( "Unrecognized Conversion System: $input{sysOut}." )
		if ( !($self->{sysOut} = Convert::Ethiopic::System->new( $input{sysOut} )) );


	if ( $self->{'cookie-7-bit'} eq "true" ) {
		if ( $self->{pragma} ) {
			$self->{pragma} .= ",7-bit" if ( $self->{pragma} !~ /7-bit/ );
		} else {
			$self->{pragma}  = "7-bit";
		}
	}


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

	$self->{sysOut}->{options} |= $self->{sysOut}->{TTName}
								  if ( $self->{sysOut}->TTName =~ /^\d$/ );

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

	1;
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
