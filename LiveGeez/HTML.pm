package LiveGeez::HTML;

require 5.000;
require Exporter;

@ISA = qw(Exporter);
@EXPORT = qw(
          FileBuffer
          );

use LiveGeez::Local;
use Convert::Ethiopic;
require HTML::Entities;


sub UpdateHREF
{
my ( $sysOut, $baseDomain, $baseURL, $scriptRoot, $args ) = @_;
my ( $link, $LGLink, $target );


    $link   = $3 if ( $args =~ /href(\s*)=(\s*)"?([^"]+)"?/i );
    $target = " target=\"$3\"" if ( $args =~ /target(\s*)=(\s*)"?(\w+)"?/i );
    $LGLink = 1 if ( $args =~ /LIVEGEEZLINK/i );


   	return ( $link =~ /^\// ) ? "<a href=\"$baseDomain$link\"$target>" : "<a $args>"
   		if ( ($link =~ /^(\w)+:/ || $link !~ "\.sera\.") && !$LGLink );


	if ( $baseURL ) {
		if ( $link =~ /^\// ) {
			$link = $baseDomain.$link;
		}
		else {
			$link = $baseURL.$link;
		}
	}
	elsif ( $baseDomain && $link !~ /^\// ) {
		# update href local files
		$link = "$baseDomain/$link";
	}

	$link =~ s#/(\w+)/\.\./#/#;  # stupid servers need this...
	return "<a href=\"$scriptRoot?sys=$sysOut&file=$link\"$target>";

}


sub UpdateSRC
{
my ( $baseDomain, $baseURL, $scriptRoot, $args ) = @_;
my ( $link, $LGLink, $target );


	$src = $3 if ( $args =~ /src(\s*)=(\s*)"?([^"]+)"?/i );

	return "<img $args>" if ( $src =~ /^(\w)+:/ );

	if ( $baseURL ) {
		$args =~ s#(")?/#$1$baseDomain/# if ( $src =~ /^\// );
	} 
	elsif ( $baseDomain ) {
		# update src for local files
		$args =~ s#(src(\s*)=(\s*)"?)#$1$baseDomain/# if ( $src !~ /^\// );
	}

	"<img $args>";

}


sub FixLink
{
my ($link, $sysPragmaOut, $scriptRoot, $baseURL) = @_;


    $link = "$scriptRoot?sys=$sysPragmaOut&file=$baseURL$link";
	$link =~ s#/(\w+)/\.\./#/#;  # stupid servers need this...
	$link;
}


sub FontMenu
{
my ( $args, $sysOut, $file ) = @_;
my ( $menu, $name, $selected, $other );


    $name      = $3 if ( $args =~ /name(\s*)=(\s*)"?(\w+)/i );
    $selected  = $3 if ( $args =~ /selected(\s*)=(\s*)"?(\w+)/i );
    $script    = $3 if ( $args =~ /script(\s*)=(\s*)"?([\w\-]+)/i );

	$name   = " name=\"$name\""            if $name;
	($selected) = split ( /\./, $sysOut )  if !$selected;
	$script = ( $script eq "js-standard" )
	#       ? " onChange=\"openLink(this.options[this.selectedIndex].value);\""
	        ? " onChange=\"window.open('$scriptURL?sys=' + this.options[this.selectedIndex].value + '&file=$file', '_top');\""
	        : " onChange=\"$script\""
	          if ( $script );



	$menu = 
   "<select$name$script>
      <option value=FirstTime>Choose A Font!</option>
      <option value=Addis>Addis One</option> 
      <option value=Addis98>Addis98</option> 
      <option value=AddisWp>AddisWP</option> 
      <option value=Agaw>Agaw</option>
      <option value=AGF-Dawit>AGF - Dawit</option>
      <option value=AGF-Zemen>AGF - Zemen</option>
      <option value=AGF-Ejji-Tsihuf>AGF - Ejji Tsihuf</option>
      <option value=AGF-Rejim>AGF - Rejim</option>
      <option value=AGF-Yigezu-Bisrat>AGF - Yigezu Bisrat</option>
      <option value=ALXethiopian>ALXethiopian</option>
      <option value=AMH3>AMH3</option>
      <option value=AmharicKechin>Amharic  Kechin</option>
      <option value=AmharicYigezuBisrat>Amharic Yigezu Bisrat</option>
      <option value=AmharicGazetta>Amharic Gazetta</option>
      <option value=Amharic>Amharic 1</option>
      <option value=AmharicBook>Amharic Book 1</option>
      <option value=Amharic_Alt>Amharic_Alt</option>
      <option value=Amharisch>Amharisch</option>
      <option value=Brana>Brana I</option>
      <option value=Amharic-A>Amharic-A</option>
      <option value=AmharQ>AmharQ</option>
      <option value=ET-NCI>ET-NCI </option>
      <option value=ET-NEBAR>ET-NEBAR</option>
      <option value=ET-Saba>ET-Saba</option>
      <option value=ET-SAMI>ET-SAMI</option>
      <option value=Ethiopia>Ethiopia Primary</option>
      <option value=EthiopiaSlanted>Ethiopia Slanted Primary</option>
      <option value=EthiopiaAnsiP>EthiopiaAnsiP</option>
      <option value=EthioSoft>EthioSoft</option>
      <option value=Ethiopic>ETHIOPIC</option>
      <option value=Fidel>FIDEL~`SOFTWARE</option>
      <option value=Geez>Geez</option>
      <option value=GeezA>GeezA</option>
      <option value=Geez-1>Ge'ez-1</option>
      <option value=Geez-2>Ge'ez-2</option>
      <option value=Geez-3>Ge'ez-3</option>
      <option value=GeezAddis>GeezAddis</option>
      <option value=geezBasic>geezBasic</option>
      <option value=GeezBausi>GeezBausi</option>
      <option value=Geezigna>Geezigna</option>
      <option value=geezLong>geezLong</option>
      <option value=GeezNewA>GeezNewA</option>
      <option value=GeezDemo>Geez Demo</option>
      <option value=GeezNet>GeezNet</option>
      <option value=GeezSindeA>GeezSindeA</option>
      <option value=GeezThin>GeezThin</option>
      <option value=GeezTimesNew>GeezTimeNew</option>
      <option value=GeezType>GeezType</option>
      <option value=GeezTypeNet>GeezTypeNet</option>
      <option value=GeezEditAmharicP>Ge&#232;zEdit Amharic P</option>
      <option value=GFZemen>GF Zemen Primary</option>
      <option value=GFZemen2K>GF Zemen2K Ahadu</option>
      <option value=HahuLite>Hahu Lite</option>
      <option value=HahuGothic>Hahu Lite Gothic</option>
      <option value=HahuSerif>Hahu Lite Serif</option>
      <option value=HahuTimes>Hahu Lite Times</option>
      <option value=JIS>JIS</option>
      <option value=JUNET>JUNET</option>
      <option value=TfanusGeez01>TfanusGeez01</option>
      <option value=UTF7>UTF7</option>
      <option value=UTF8>UTF8</option>
      <option value=java>\\uabcd</option>
      <option value=Java.uppercase>\\uABCD</option>
      <option value=clike>\\xabcd</option>
      <option value=Clike.uppercase>\\xABCD</option>
      <option value=VG2-Agazian>VG2 Agazian</option>
      <option value=VG2-Main>VG2 Main</option>
      <option value=VG2-Title>VG2 Title</option>
      <option value=Washra>Washra  Primary</option>
      <option value=Washrasl>Washrasl  Primary</option>
      <option value=Wookianos>Wookianos Primary</option>
      <option value=Yebse>Yebse Primary</option>
  </select>";

	$menu =~ s/$selected>/$selected selected>/ if ( $selected );

	$menu;

}


sub FileBuffer
{
my $file = shift;
my $pragmi;
my ( $scriptRoot ) = ( $file->{baseURL} ) 
                   ? $file->{request}->{scriptURL} 
                   : $file->{request}->{scriptBase}
                   ;


	$_ = Convert::Ethiopic::ConvertEthiopicString (
		 $file->{htmlData},
		 $file->{request}->{sysIn}->{sysNum},
		 $file->{request}->{sysIn}->{xferNum},
		 $file->{request}->{sysOut}->{sysNum},
		 $file->{request}->{sysOut}->{xferNum},
		 $file->{request}->{sysOut}->{fontNum},
		 $file->{request}->{sysOut}->{langNum},
		 $file->{request}->{sysOut}->{iPath},
		 $file->{request}->{sysOut}->{options},
		 0    #  </font> closing
	);

	my $sysOut = $file->{request}->{sysOut}->{sysName};
	$sysOut .= ".$file->{request}->{sysOut}->{xfer}"
			if ( $file->{request}->{sysOut}->{xfer} ne "notv" );
	$sysPragmaOut = ( $file->{request}->{pragma} )
	              ?  "$sysOut&pragma=$file->{request}->{pragma}"
	              :  $sysOut
	              ;

	s/LIVEGEEZSYS/$sysOut/g;
	s/<a(\s+)(href[^>]+)>/UpdateHREF($sysPragmaOut, $file->{baseDomain}, $file->{baseURL}, $scriptRoot, $2)/oeig;
	s/<img([\s\w,="]+src[^>]+)>/UpdateSRC($file->{baseDomain}, $file->{baseURL}, $scriptRoot, $1)/oeig;
	s/<frame([^>]+)src="?([^"]+)"?/"<frame$1src=\"".FixLink($2,$sysPragmaOut,$scriptRoot,$file->{baseURL})."\""/oeig;

	#
	#  Calendar Links
	#
	s/datesys/cal/g;
	s/cal=/sys=$sysPragmaOut&cal=/g;

	#
	#  Forms
	#
	s/action(\s+)?=(\s+)?(")?LIVEGEEZLINK(")?/action="$scriptRoot"/oig;


	s/<LIVEGEEZMENU(\s+value[^>]+)?>/<form$1 LIVEGEEZFORM>\n<\/form>/oig;
	s/<form(\s+)(value[^>]+?)?LIVEGEEZFORM>/<form LIVEGEEZPOST>\n  <LIVEGEEZ FORMFILE>\n  <LIVEGEEZ FORMCOOKIE>\n  <LIVEGEEZ FORMMENU>\n  <LIVEGEEZ $2FORMSUBMIT>/oig;
	s/<form([\s\w,="]+)LIVEGEEZPOST>/<form$1action="$scriptRoot" method="GET">/oig;
	s/<LIVEGEEZ(\s+)FORMFILE>/<input type="hidden" name="file" value="$file->{request}->{file}">/oig;
	s/<LIVEGEEZ(\s+)FORMCOOKIE>/<input type="hidden" name="setcookie" value="true">/oig;
	s/<LIVEGEEZ(\s+)FORMMENU>/FontMenu("name=\"sysOut\"", $sysOut, $file->{request}->{file})/oieg;
	s/<LIVEGEEZ(\s+)(value(\s*)=(\s*)"?([^"]+)"?(\s+))?FORMSUBMIT>/my $value = ( $5 ) ? $5 : "Reopen"; "<input type=\"submit\" value=\"$value\">"/oeig;
	s/<LIVEGEEZ(\s+)FORMMACFRIENDLY>/<nobr><input type="checkbox" name="pragma" value="7-bit"> Mac Friendly<\/nobr>/oig;
	s/(value="7-bit")>/$1 checked>/ if ( $file->{request}->{sysOut}->{'7-bit'} );
	s/<LIVEGEEZ([\s\w,="]+menu([^>]+)?)>/FontMenu($1, $sysOut, $file->{request}->{file})/imge;
	


	if ( $sysOut =~ "JIS" ) {  # this should be in the jis filter, but this is easier
		s/\&laquo;/þü/ig;
		s/\&#171;/þü/g;
		s/\&raquo;/þý/ig;
		s/\&#187;/þý/g;
	}

	if ( $file->{baseURL} 
	     && (!/<base/i || (/<(base)([^>]+)>/i && $2 !~ /href/i)) )
	{
		if ( $1 ) {
			s/<(base)([^>]+)>/<$1$2 href="$file->{baseURL}">/i;
		} else {
			s/(<body)/<base href="$file->{baseURL}">\n$1/i;
		}
	}

	$_ = HTML::Entities::encode($_, "\200-\377")
  		 if ( $file->{request}->{sysOut}->{'7-bit'} );

	$file->{htmlData} = $_;

	1;
}
#########################################################
# Do not change this, Do not put anything below this.
# File must return "true" value at termination
1;
##########################################################


__END__


=head1 NAME

LiveGeez::HTML - HTML Conversions for LiveGe'ez

=head1 SYNOPSIS

FileBuffer ( $f );  # Where $f is a File.pm object.

=head1 DESCRIPTION

HTML.pm contains the routines for conversion of HTML document content between
Ethiopic encoding systems and for pre-interpretation of HTML markups for
compliance with the LiveGe'ez Remote Processing Protocol.

=head1 AUTHOR

Daniel Yacob,  L<LibEth@EthiopiaOnline.Net|mailto:LibEth@EthiopiaOnline.Net>

=head1 SEE ALSO

S<perl(1).  Ethiopic(3).  L<http://libeth.netpedia.net/LiveGeez.html|http://libeth.netpedia.net/LiveGeez.html>>

=cut
