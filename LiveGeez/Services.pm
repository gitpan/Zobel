package LiveGeez::Services;

require 5.000;
require Exporter;

@ISA = qw(Exporter);
@EXPORT = qw(
			ProcessRequest
			ProcessDate
			ProcessFortune
			ProcessNumber
			ProcessString
			ProcessFile
			AboutLiveGeez
			);

require LiveGeez::File;
require Convert::Ethiopic;
require Convert::Ethiopic::Time;
require Convert::Ethiopic::Cstocs;
require HTML::Entities;

$fortuneDir       = "$Local::webRoot/fortunes/";
($unicode, $utf8) = ( $Convert::Ethiopic::System::unicode,  $Convert::Ethiopic::System::utf8 );


#------------------------------------------------------------------------------#
#
# "ProcessFortune"
#
#	Opens a stream to the fortune routine and grabs an Ethiopic fortune in
#	UTF8 and returns the result converted in the $sysOut system.  This works
#	presently with any cgi "fortune" querry.  It has not been tested yet
#	with inline <LIVEGEEZ game="fortune" src="database"> markups.
#	
#	"phrase" pragma is checked to return response as complete HTML document. 
#
#------------------------------------------------------------------------------#
sub ProcessFortune
{
my $request = shift;


	open (FORTUNE, "fortune $fortuneDir |");
	my $fortune = Convert::Ethiopic::ConvertEthiopicFileToString (
		\*FORTUNE,
		$unicode,
		$utf8,
		$request->{sysOut}->{sysNum},
		$request->{sysOut}->{xferNum},
		$request->{sysOut}->{fontNum},
		$request->{sysOut}->{langNum},
		$request->{sysOut}->{iPath},
		$request->{sysOut}->{options}
	);
	close (FORTUNE);

	$fortune =~ s/\n/<br>$&/g;

	$fortune = HTML::Entities::encode($fortune, "\200-\377")
			   if ( $request->{sysOut}->{'7-bit'} );

	$fortune = $request->TopHtml ( "Your Ethiopian Fortune!" )
			 . $fortune
			 . $request->BotHtml 
			   if ( $request->{phrase} );

	$fortune;

}


#------------------------------------------------------------------------------#
#
# "ProcessNumber"
#
#   Service for numeral conversion between Arabic and Ethiopic systems.
#	
#	"phrase" pragma is checked to return response as complete HTML document. 
#
#------------------------------------------------------------------------------#
sub ProcessNumber
{
my $request = shift;


	my $eNumber = Convert::Ethiopic::Cstocs::EthiopicNumber ( $request );

	$eNumber = $request->TopHtml ( "Converting $request->{number} into Ethiopic..." )
			 . "$request->{number} is "
			 . "$eNumber\n"
			 . $request->BotHtml
			   if ( $request->{phrase} );

	$eNumber;

}


sub ProcessString 
{
my $request = shift;


	my  $eString = Convert::Ethiopic::ConvertEthiopicString (
		$request->{string},
		$request->{sysIn}->{sysNum},
		$request->{sysIn}->{xferNum},
		$request->{sysOut}->{sysNum},
		$request->{sysOut}->{xferNum},
		$request->{sysOut}->{fontNum},
		$request->{sysOut}->{langNum},
		$request->{sysOut}->{iPath},
		$request->{sysOut}->{options},
		1       #  closing
	);

	if ( $request->{sysOut}->{sysName} eq "sera" ) {
		$eString =~ s/<</&#171;/g;
		$eString =~ s/>>/&#187;/g;
	}

	$eString = HTML::Entities::encode($eString, "\200-\377")
			   if ( $request->{sysOut}->{'7-bit'} );

	$estring =~ s/\xa0/&nbsp;/g;  # wish HTML::Entities didn't do this..

	$eString = $request->TopHtml ( "Your Ethiopic Phrase!" )
			 . "$eString\n"
			 . $request->BotHtml
			   if ( $request->{phrase} );

	$eString;

}


#------------------------------------------------------------------------------#
#
# "AboutLiveGeez"
#
#	Tell the enquiring mind about the LiveGe'ez / LibEth.  This is the current
#	default response to any "about" querry.  Later we might add extras such as
#	AboutGFF, AboutENH, etc.
#
#------------------------------------------------------------------------------#
sub AboutLiveGeez
{
my $request = shift;


	print $request->TopHtml ( "About LiveGe'ez &amp; LibEth" );
	my $leVersion = Convert::Ethiopic::LibEthVersion;
	print <<ABOUT;
<h1 align="center">About LiveGe'ez &amp; LibEth</h1>

<p>This is the GFF implementation of the LiveGe'ez Remote Processing Protocal.  Ethiopic web service is performed through a collection of CGI scripts (Zobel v.0.09) written in Perl interfaced with the LibEth library (v. $leVersion).</p>
<h3>For More Information Visit:</h3>
<ul>
  <li> <a href="http://libeth.netpedia.net/">LibEth</a>
  <li> <a href="http://libeth.netpedia.net/Zobel/">Zobel</a>
  <li> <a href="http://libeth.netpedia.net/LiveGeez.html">LiveGe'ez</a>
</ul>
ABOUT
	print $request->BotHtml;
	exit (0);

}


sub ProcessDate
{
my $request = shift;
my ( $day, $month, $year ) = split ( ",", $request->{date} );
my ( $xDay, $xMonth, $xYear );
my $returnDate;


	#
	# Instantiate a Date Object
	#

	my $date = Convert::Ethiopic::Time->new ( $request );


	#
	# Convert from Passed Date 
	#
	if ( $request->{calIn} eq "ethio" ) {
		$date->EthiopicToGregorian;
	}
	else {  # we assume euro for now
		$date->GregorianToEthiopic;
	}


	($xDay, $xMonth, $xYear) = ( $request->{calIn} eq "ethio" )
	                         ?  ( $date->{etDay}, $date->{etMonth}, $date->{etYear} )
	                         :  ( $date->{euDay}, $date->{euMonth}, $date->{euYear} )
	                         ;


	if ( $request->{'date-only'} ) {
		$returnDate = "$xDay,$xMonth,$xYear\n";
	}
	elsif ( $request->{'is-holiday'} && $request->{phrase} ) {
		$returnDate = $date->isEthiopianHoliday;

		if ( $returnDate ) {
			my ( $Day, $Month ) = $date->getDayMonthYearDayName;
			$phrase  = "$Day�� $Month $date->{etDay} ";
			$phrase .= ( $request->{lang} eq "amh" ) ?  "ቀን" : "መዓልቲ";
			$phrase .= " $returnDate ";
			$phrase .= ( $request->{lang} eq "amh" ) ? "ነው።" : "እዩ።" ;
			$phrase  = Convert::Ethiopic::ConvertEthiopicString (
				$phrase,
				$unicode,
				$utf8,
				$request->{sysOut}->{sysNum},
				$request->{sysOut}->{xferNum},
				$request->{sysOut}->{fontNum},
				$request->{sysOut}->{langNum},
				$request->{sysOut}->{iPath},
				$request->{sysOut}->{options},
				1       #  closing
			);
		}
		else {
			$phrase = "$date->{etDay}/$date->{etMonth}/$date->{etYear} is <u>not</u> a holiday.\n"
		}

		$returnDate = $request->TopHtml ( "Checking Holidy for $date->{etDay}/$date->{etMonth}/$date->{etYear}" )
				 	. $phrase
				 	. $request->BotHtml
					;
	}
	elsif ( $request->{'is-holiday'} ) {
		$returnDate  = ( $date->isEthiopianHoliday ) ? "1" : "0" ;
		$returnDate .= "\n";
	}
	elsif ( !$request->{phrase} ) {

		my ( $etDoW, $etMonthName, $etNumYear, $etDayName ) 
						  = $date->getDayMonthYearDayName;
		my ($euDoW)		  = $date->getEuroDayOfWeek;
		my ($euMonthName) = $date->getEuroMonth;
		my ($etDate)      = "$etDoW፣ $etMonthName $date->{etDay} $etNumYear ";


		if ( $request->{sysOut}->{LCInfo} ) {
			$etDate = Convert::Ethiopic::ConvertEthiopicString (
							$etDate,
							$unicode,
							$utf8,
							$request->{sysOut}->{sysNum},
							$request->{sysOut}->{xferNum},
							$request->{sysOut}->{fontNum},
							$request->{sysOut}->{langNum},
							$request->{sysOut}->{iPath},
							$request->{sysOut}->{options},
							1       #  closing
			);

			$etDayName = Convert::Ethiopic::ConvertEthiopicString (
							$etDayName,
							$unicode,
							$utf8,
							$request->{sysOut}->{sysNum},
							$request->{sysOut}->{xferNum},
							$request->{sysOut}->{fontNum},
							$request->{sysOut}->{langNum},
							$request->{sysOut}->{iPath},
							$request->{sysOut}->{options},
							1       #  closing
			);
		}

		if ( $request->{calIn} eq "euro" ) {
			#
			# Convert from European -> Ethiopian
			#
			$phrase = $request->TopHtml ( "From The European Calendar To The Ethiopian" )
					. "<h3>$euDoW, $euMonthName $date->{euDay}, $date->{euYear}"
					. " <i><font color=blue><u>is</u></font></i> "
					. $etDate
					. " <i>(<font color=red>$etDayName</font>)</i></h3>\n";
		} else {
			#
			# Convert from Ethiopian -> European
			#
			$phrase = $request->TopHtml ( "From The Ethiopian Calendar To The European" )
					. "<h3>"
			        . $etDate
					. " <i><font color=blue><u>is</u></font></i> "
					. "$euDoW, $euMonthName $date->{euDay}, $date->{euYear}"
					. " <i>(<font color=red>$etDayName</font>)</i></h3>\n";
		} 


		$phrase =~ s/፣/,/ unless ( $request->{sysOut}->{LCInfo} );

		$returnDate = $phrase . $request->BotHtml;
					 
  	}

	$returnDate = HTML::Entities::encode($returnDate, "\200-\377")
				  if ( $request->{sysOut}->{'7-bit'} );


	$returnDate;

}


sub ProcessRequest
{
my $r = shift;


	$r->HeaderPrint;

	if ( $r->{type} eq "file") {
		# Only SERA supported at this time...
		my $f = LiveGeez::File->new ( $r );
		$f->Display;
	}
	elsif ( $r->{type} eq "calendar" ) {

		# What time is it??
		$r->DieCgi ( "Unsupported Calendar System: $r->{calIn}" )
			if ( $r->{calIn} && $r->{calIn}   !~ /(ethio)|(euro)/ );
		$r->DieCgi ( "Unsupported Calendar System: $r->{calOut}" )
			if ( $r->{calOut} && $r->{calOut} !~ /(ethio)|(euro)/ );
		
    	print ProcessDate ( $r );
	}
	elsif ( $r->{type} eq "string" ) {
		# Only SERA supported at this time...
		print ProcessString ( $r );
	}
	elsif ( $r->{type} eq "number" ) {
		# We have a number request...
		print ProcessNumber ( $r );
	}
	elsif ( $r->{type} eq "game-fortune" ) {
		# A random fortune from our vast library...
		print ProcessFortune ( $r );
	}
	elsif ( $r->{type} eq "about" ) {
		#  For folks who want to know more... 
		AboutLiveGeez ( $r );
	}
	else {
		return ( 0 );
	}

	1;

}
#########################################################
# Do not change this, Do not put anything below this.
# File must return "true" value at termination
1;
##########################################################


__END__


=head1 NAME

LiveGeez::Services - Request Processing Services for LiveGe'ez

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

Services.pm provides request processing services for a LiveGe'ez query
as specified in the LiveGe'ez Remote Processing Protocol.  "ProcessRequest"
takes a LiveGe'ez LiveGeez::Request object and performs the appropriate
service.

=head1 AUTHOR

Daniel Yacob,  L<LibEth@EthiopiaOnline.Net|mailto:LibEth@EthiopiaOnline.Net>

=head1 SEE ALSO

S<perl(1).  Ethiopic(3).  L<http://libeth.netpedia.net/LiveGeez.html|http://libeth.netpedia.net/LiveGeez.html>>

=cut
