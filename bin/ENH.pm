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



sub UpdateHTMLBuffer
{
local ($file) = shift;


	$_ = $file->{htmlData};


	#------------------ For Articles
	s/<\/body>/"<\/body>".writeMailToUpdate($file)/ie
		if ( $file->{request}->{isArticle} );


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
local ($string);


    $string = qq(<link rel=FONTDEF src="$fontURL">
    <!-- start Bitstream TDServer.ocx support -->
    <SCRIPT LANGUAGE="JavaScript"
        SRC="http://www.truedoc.com/activex/tdserver.js">
    </SCRIPT>
    <!-- end Bitstream TDServer.ocx support -->
    <link>);

	return ( $string );
}



sub writeMenuHeader 
{
local ($request) = shift;
local ($string);
local ($sys)     =  ( $request->{pragma} )
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

	return ($string);

}



sub writeMailToUpdate
{
local ($file) = shift;
local ($string);
local ($mailToString) = ( $file->{request}->{frames} eq "no" ) 
                      ?   "mailToURL"
                      :   "parent.mailToURL"
                      ;

	$string = qq(\n<script language="JavaScript">
<!--
  $mailToString += "$file->{request}->{file}";
//------------------------------------------------------------------ -->
</script>\n\n);

	return ($string);

}



sub DateSomething
{
local $r = shift;


	#
	# Instantiate a Date Object
	#

	$r->{calIn}   = "euro";
	@timeNow      = localtime;
	$r->{euDay}   = $timeNow[3];
	$r->{euMonth} = $timeNow[4] + 1;
	$r->{euYear}  = $timeNow[5] + 1900;

	local ( $date ) = Convert::Ethiopic::Time->new ( $r );


	$date->GregorianToEthiopic;


	$string = "<table width=640 cellpadding=0 cellspacing=0>\n  <tr><td align=left width=33%>"
	        . $date->getEuroMonth
	        . " $date->{euDay}, $date->{euYear}</td>\n"
	        . "<td align=center width=34%><font color=teal size=+1><font color=teal><b>";


	$r->{string}           = "ye".$r->{sysOut}->HTMLName." dre geS";
	my $tempSysInNum       = $r->{sysIn}->{sysNum};
	my $tempxferInNum      = $r->{sysIn}->{xferNum};
	$r->{sysIn}->{sysNum}  = $sera;
	$r->{sysIn}->{xferNum} = $notv;
	$string               .= ProcessString ( $r )
	                      . "</b></font></td><td align=right><a href=\"/ECalendars/ecalendars.cgi?sys=$sys\"><font color=\"black\">";
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

	return ( $string );

}



sub OpenFrameSet
{
local ( $request )   = shift;
local ( $frame )     = shift;
local ( $frameRoot ) = "misc/Frames";
local ( $file  )     = $request->{file};
local ( $sysOut )    = $request->{sysOut}->{sysName};
local ( $fileSysOut );
local ( $sysPragmaOut );


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


local ( $TOP ) 	  =  ( -e "$FileCacheDir/$frameRoot/addtop.$fileSysOut.html" ) 
				  ?  "$FileCacheDir/$frameRoot/addtop.$fileSysOut.html"
				  :  "$scriptBase?sys=$sysPragmaOut&file=$frameRoot/addtop.sera.html"
				  ;
local ( $LEFT )	  =  ( -e "$FileCacheDir/$frameRoot/left.$fileSysOut.html" ) 
				  ?  "$FileCacheDir/$frameRoot/left.$fileSysOut.html"
				  :  "$scriptBase?sys=$sysPragmaOut&file=$frameRoot/left.sera.html"
				  ;
local ( $RIGHT )  =  ( -e "$FileCacheDir/$frameRoot/right.$fileSysOut.html" ) 
				  ?  "$FileCacheDir/$frameRoot/right.$fileSysOut.html"
				  :  "$scriptBase?sysPragmaOut=$fileSysOut&file=$frameRoot/right.sera.html"
				  ;

local ( $FILE )   =  "$scriptBase?sys=$sysPragmaOut&file=$file&frames=skip";


	open (FRAME, "$webRoot/$frame") || &CgiDie ("!: Can't Open $frame\n");

	print PrintHeader;
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
local ( $r ) = shift;


	my ( $f ) = LiveGeez::File->new ( $r );


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
		FileBuffer ($f);


		#
		# Retranslate buffer.
		#
		UpdateHTMLBuffer ($f);


		#
		# Display it!
		#
		$f->DisplayFileAndCache;
	}

}



sub ProcessNoFramesFile
{
local ( $r ) = shift;
local ( $articleFile ) = $r->{file};
local ( $TEMPLATETOP ) = "misc/NoFrames/left.sera.html";
local ( $TEMPLATEBOT ) = "misc/NoFrames/right.sera.html";



	my ( $f )  = LiveGeez::File->new ( $r );


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
		my ( $top ) = LiveGeez::File->new ( $r );


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
		my ( $bot ) = LiveGeez::File->new ( $r );


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
		FileBuffer ($f);


		#
		# Retranslate buffer.
		#
		UpdateHTMLBuffer ($f);


		#
		# Display it.
		#
		$f->DisplayFileAndCache;
	}


}


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
