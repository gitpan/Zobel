package ENH;

require 5.000;
require Exporter;

@ISA = qw(Exporter);
@EXPORT = qw(
			OpenFrameSet
			ProcessFramesFile
			ProcessNoFramesFile
			);

use LiveGeez::Local;
use LiveGeez::File;
use LiveGeez::Services;
use LiveGeez::HTML;
use Convert::Ethiopic::Time;

($unicode, $utf8, $sera, $notv) = (
	$Convert::Ethiopic::System::unicode,
	$Convert::Ethiopic::System::utf8,
	$Convert::Ethiopic::System::sera,
	$Convert::Ethiopic::System::notv
	);



sub UpdateHTMLBuffer
{
my $file = shift;


	$_ = $file->{htmlData};


	#------------------ For Articles
	# s/<\/body>/"<\/body>".writeMailToUpdate($file)/ie
	# 	if ( $file->{request}->{isArticle} );


	#------------------ For NoFrames Main Page
	if ( $file->{request}->{mainPage} && $file->{request}->{frames} eq "no" ) {
    	s/value="Frames Off"/value="Frames On"/;
        s/action="\/NoFrames.pl"/action="\/G.pl"/;
        s/name="frames" value="yes"/name="frames" value="YES"/;
        s/name="frames" value="no"/name="frames" value="yes"/;
        s/name="frames" value="YES"/name="frames" value="no"/;
	}


	#------------------ For All
	s/<LIVEGEEZ date="Now">/DateSomething($file->{request})/ie;
	s/<LIVEGEEZTITLE>/<html>\n<head>\n  <title>$file->{Title}<\/title>\n<\/head>/;
	s/<body/writeMenuHeader ($file->{request})."<body"/ie
		if ( $file->{request}->{mainPage} );


	$file->{htmlData} = $_;
}



sub writePFRHeader 
{
my $string;


    $string = qq(<link rel=FONTDEF src="$fontURL">
    <!-- start Bitstream TDServer.ocx support -->
    <script language="JavaScript"
        SRC="http://www.truedoc.com/activex/tdserver.js">
    </script>
    <!-- end Bitstream TDServer.ocx support -->
    <link>);


	$string;
}



sub writeMenuHeader 
{
my $request = shift;
my $string;
my $sys     =  ( $request->{pragma} )
            ?   "$request->{sysOut}->{sysName}&pragma=$request->{pragma}"
            :    $request->{sysOut}->{sysName}
            ;


	$string = qq(<script language="JavaScript">
<!--
var system = "$sys";
var urlPrefix = "$request->{scriptBase}?sys=" + system + "&file=/";

function updateURLPrefix(newSystem) {
    system = parent.system = newSystem;
    urlPrefix = "$request->{scriptBase}?sys=" + system + "&setcookie=true&frames=yes" + "&file=/index.sera.html";
}

function openLink(sys) {
    updateURLPrefix(sys);
    window.open(urlPrefix, '_top');
}

function openSpecials (file) {
    window.open(urlPrefix + file, '_top');
}
//------------------------------------------------------------------ -->
</script>\n\n);

$string .= qq(
<SCRIPT LANGUAGE="JavaScript">
<!-- Original:  Randy Bennett (rbennett\@thezone.net) -->
<!-- Web Site:  http://home.thezone.net/~rbennett/utility/javahead.htm -->

<!-- Begin
function setupDescriptions() {
var x = navigator.appVersion;
y = x.substring(0,4);
if (y>=4) setVariables();
}
var x,y,a,b;
function setVariables(){
if (navigator.appName == "Netscape") {
h=".left=";
v=".top=";
dS="document.";
sD="";
}
else
{
h=".pixelLeft=";
v=".pixelTop=";
dS="";
sD=".style";
   }
}
var isNav = (navigator.appName.indexOf("Netscape") !=-1);
function popLayer(){
desc = "<table cellpadding=3 border=1 bgcolor=F7F7F7><td>";

desc += word;

desc += "</td></table>";

if(isNav) {
document.object1.document.write(desc);
document.object1.document.close();
document.object1.left=x+25;
document.object1.top=y;
}
else {
object1.innerHTML=desc;
eval(dS+"object1"+sD+h+(x+25));
eval(dS+"object1"+sD+v+y);
   }
}
function hideLayer(a){
if(isNav) {
eval(document.object1.top=a);
}
else object1.innerHTML="";
}
function handlerMM(e){
x = (isNav) ? e.pageX : event.clientX;
y = (isNav) ? e.pageY : event.clientY;
}
if (isNav){
document.captureEvents(Event.MOUSEMOVE);
}
document.onmousemove = handlerMM;
//  End -->
</script>\n\n);

	# $string .= writePFRHeader if ( $sys =~ "GFZemen2K" );

	$string;
}



sub writeMailToUpdate
{
my $file = shift;
my $string;
my $mailToString = ( $file->{request}->{frames} eq "no" ) 
                 ?   "mailToURL"
                 :   "parent.mailToURL"
                 ;

	$string = qq(\n<script language="JavaScript">
<!--
  $mailToString += "$file->{request}->{file}";
//------------------------------------------------------------------ -->
</script>\n\n);


	$string;
}



sub DateSomething
{
my $r = shift;


	#
	# Instantiate a Date Object
	#

	$r->{calIn}   = "euro";
	@timeNow      = localtime;
	$r->{euDay}   = $timeNow[3];
	$r->{euMonth} = $timeNow[4] + 1;
	$r->{euYear}  = $timeNow[5] + 1900;

	my $date      = Convert::Ethiopic::Time->new ( $r );


	$date->GregorianToEthiopic;

	my $etDayName = Convert::Ethiopic::getEthiopicDayName ( $date->{etDay}, $date->{etMonth}, 512 ); 
	$etDayName = "<font color=red>"
	. Convert::Ethiopic::ConvertEthiopicString (
						$etDayName,
						$unicode,
						$utf8,
						$r->{sysOut}->{sysNum},
						$r->{sysOut}->{xferNum},
						$r->{sysOut}->{fontNum},
						$r->{sysOut}->{langNum},
						$r->{sysOut}->{iPath},
						$r->{sysOut}->{options},
						1       #  closing
		)
		. "</font>"
	;
	# $r->{string} = Convert::Ethiopic::getEthiopicDayName ( $date->{etDay}, $date->{etMonth}, 1024 ); 
	# my $etDayName = "<font color=red>".ProcessString ( $r )."</font>";
	$etDayName =~ s/"/\\"/g;

	$string = "<script languages=\"JavaScript\">\nword = \"$etDayName\";\n</script>\n\n";

	$string .= "<table width=640 cellpadding=0 cellspacing=0>\n  <tr><td align=left width=33%>"
	        . $date->getEuroMonth
	        . " $date->{euDay}, $date->{euYear}</td>\n"
	        . "<td align=center width=34%><font color=teal size=+1><font color=teal><b>";

	my $englishName  = Convert::Ethiopic::getEthiopicDayName ( $date->{etDay}, $date->{etMonth}, 0 );

	$r->{string}           = "ye".$r->{sysOut}->HTMLName."  dre geS";
	my $tempSysInNum       = $r->{sysIn}->{sysNum};
	my $tempxferInNum      = $r->{sysIn}->{xferNum};
	$r->{sysIn}->{sysNum}  = $sera;
	$r->{sysIn}->{xferNum} = $notv;
	$string               .= ProcessString ( $r )
	                      . "</b></font></td><td align=right><a href=\"/ECalendars/ecalendars.cgi?sys=$r->{sysOut}->{sysName}\" onMouseOver=\"popLayer(); status='$englishName';return true;\" onMouseOut=\"hideLayer(-50)\"><font color=\"black\">";
	                      # . "</b></font></td><td align=right><a href=\"/ECalendars/ecalendars.cgi?sys=$r->{sysOut}->{sysName}\" onMouseOver=\"status='$englishName'\"><font color=\"black\">";
	                      # . "</b></font></td><td align=right><a href=\"/ECalendars/ecalendars.cgi?sys=$r->{sysOut}->{sysName}\"><font color=\"black\">";
	$r->{sysIn}->{sysNum}  = $tempSysInNum;
	$r->{sysIn}->{xferNum} = $tempxferInNum;


	$r->{string}           = $date->getEthioMonth." $date->{etDay}፣ ";
	$tempSysInNum          = $r->{sysIn}->{sysNum};
	$tempxferInNum         = $r->{sysIn}->{xferNum};
	$r->{sysIn}->{sysNum}  = $unicode;
	$r->{sysIn}->{xferNum} = $utf;
	$string               .= ProcessString ( $r );
	$r->{sysIn}->{sysNum}  = $tempSysInNum;
	$r->{sysIn}->{xferNum} = $tempxferInNum;


	$r->{number} = $date->{etYear};
	$string .= ProcessNumber ( $r )
			. "</font></a></td></tr></table>\n";


	$string .= "<hr>Greetings. You are accessing the ENH either for the first time or with a font sytem no longer supported (such as \"Image\" and \"PFR\").  Please try installing any of the <a href=\"/info/faq.html#FreeFonts\"><font color=\"blue\">free fonts</font></a> available on the Internet."
		if ( $r->{FirstTime} );


	$string;
}



sub OpenFrameSet
{
my ( $request, $frame ) = ( shift, shift );
my $frameRoot = "misc/Frames";
my $file      = $request->{file};
my $sysOut    = $request->{sysOut}->{sysName};
my ( $fileSysOut, $sysPragmaOut );


	$sysOut      .= ".$request->{sysOut}->{xfer}"
			 		  if ( $request->{sysOut}->{xfer} ne "notv" );
	$sysPragmaOut = ( $request->{pragma} )
	              ?  "$sysOut&pragma=$request->{pragma}"
	              :   $sysOut
	              ;

	$fileSysOut   =   $request->{sysOut}->{sysName};
	$fileSysOut  .= ".$request->{sysOut}->{xfer}"
					  if ( $request->{sysOut}->{xfer} ne "notv" );
	$fileSysOut  .= ".7-bit"
					  if ( $request->{sysOut}->{'7-bit'} );
	$fileSysOut  .= ".$request->{sysOut}->{options}"
					  if ( $request->{sysOut}->{options} );
	$fileSysOut  .= ".$request->{sysOut}->{lang}";


my $TOP 	  =  ( -e "$FileCacheDir/$frameRoot/addtop.$fileSysOut.html" ) 
			  ?  "$FileCacheDir/$frameRoot/addtop.$fileSysOut.html"
			  :  "$scriptBase?sys=$sysPragmaOut&file=$frameRoot/addtop.sera.html"
			  ;
my $LEFT	  =  ( -e "$FileCacheDir/$frameRoot/left.$fileSysOut.html" ) 
			  ?  "$FileCacheDir/$frameRoot/left.$fileSysOut.html"
			  :  "$scriptBase?sys=$sysPragmaOut&file=$frameRoot/left.sera.html"
			  ;
my $RIGHT  =  ( -e "$FileCacheDir/$frameRoot/right.$fileSysOut.html" ) 
			  ?  "$FileCacheDir/$frameRoot/right.$fileSysOut.html"
			  :  "$scriptBase?sysPragmaOut=$fileSysOut&file=$frameRoot/right.sera.html"
			  ;

my $cacheFile = $file;
$cacheFile  =~ s/sera/$fileSysOut/;
$cacheFile .= ".gz";

my $FILE	   =  ( -e "$FileCacheDir/$cacheFile" && $ENV{HTTP_ACCEPT_ENCODING} =~ "gzip" && $ENV{HTTP_USER_AGENT} !~ "MSIE" )
            ? "$FileCacheDir/$cacheFile"
            : "$scriptBase?sys=$sysPragmaOut&file=$file&frames=skip"
            ;
# my ( $FILE )   =  "$scriptBase?sys=$sysPragmaOut&file=$file&frames=skip";


	open (FRAME, "$webRoot/$frame") || $r->DieCgi ( "!: Can't Open $frame\n" );

	while ( <FRAME> ) {
		s/LIVEGEEZFILE/$FILE/;
		s/LIVEGEEZTOP/$TOP/;
		s/LIVEGEEZLEFT/$LEFT/;
		s/LIVEGEEZRIGHT/$RIGHT/;
		print;
	}

}



sub ProcessFramesFile
{
my $r = shift;


	my $f = LiveGeez::File->new ( $r );


	#
	# Read data into ->{htmlData} if file is cached.
	#
	if ( $f->{isCached} ) {
		$f->DisplayFromCache;
	}
	else {

		#
		# Translate buffer.
		#
		FileBuffer ( $f );


		#
		# Retranslate buffer.
		#
		UpdateHTMLBuffer ( $f );


		#
		# Display it!
		#
		$f->DisplayFileAndCache;
	}

}



sub ProcessNoFramesFile
{
my $r = shift;
my $articleFile = $r->{file};
my $TEMPLATETOP = "misc/NoFrames/left.sera.html";
my $TEMPLATEBOT = "misc/NoFrames/right.sera.html";



	my $f  = LiveGeez::File->new ( $r );


	#=======================================================================
	#
	# If we've done this before, just display and quit.
	#
	if ( $f->{isCached} ) {
		$f->DisplayFromCache;
	} else {
		#=======================================================================
		#
		# Otherwise create the file from components, display and cache.
		#


		#=======================================================================
		#
		# Top of File
		#

		$r->{file}  = $TEMPLATETOP;
		my $top = LiveGeez::File->new ( $r );


		#=======================================================================
		#
		# Middle of File
		#

		$f->{Title}  = $1 if ( $f->{htmlData} =~ /<title>([^<]+)<\/title>/is );
		$f->{htmlData} =~ s/<(\/)?html>//ogi;
		$f->{htmlData} =~ s/<(\/)?head>//ogi;
		$f->{htmlData} =~ s/<title>([^>]+)<\/title>//ois;
		$f->{htmlData} =~ s/<(\/)?body([^>]+)?>//ogis;
		# $f->{htmlData} =~ s/<\/body>//i;


		#=======================================================================
		#
		# Bottom of File
		#

		$r->{file}  = $TEMPLATEBOT;
		my $bot     = LiveGeez::File->new ( $r );


		#=======================================================================
		#
		# All together now...
		#
		$f->{htmlData} = $top->{htmlData} 
					      . $f->{htmlData} 
					      . $bot->{htmlData} 
					      ;

		$r->{file} = $articleFile;


		#
		# Translate buffer.
		#
		FileBuffer ( $f );


		#
		# Retranslate buffer.
		#
		UpdateHTMLBuffer ( $f );


		#
		# Display it.
		#
		$f->DisplayFileAndCache;
	}


}
1;

__END__


=head1 NAME

ENH -- Specialized Front End to the LiveGe'ez Package.

=head1 SYNOPSIS

use ENH;

=head1 DESCRIPTION

ENH.pm is called by the "G.pl" script used at The Ethiopian New Headlines
and Tobia for specialized file output for HTML formatting with frames, etc.

=head1 AUTHOR

Daniel Yacob,  L<LibEth@EthiopiaOnline.Net|mailto:LibEth@EthiopiaOnline.Net>

=head1 SEE ALSO

S<perl(1).  LiveGeez(3).  Ethiopic(3).  L<http://libeth.netpedia.net|http://libeth.netpedia.net>>

=cut
