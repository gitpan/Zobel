require "/home/enh/HTML/cgi/cgi-lib.pl";


sub getCookies {
# cookies are seperated by a semicolon and a space, this will split
# them and return a hash of cookies
local ( @rawCookies ) = split ( /; /, $ENV{'HTTP_COOKIE'} );
local ( %cookies );


	foreach ( @rawCookies ) {
    	if ( /prefs/ ) {
 			($prefs, $key1, $val1, $key2, $val2, $key3, $val3) = split ( /[=&]/, $_ );
    	   	$cookies{$key1} = $val1;                     # system
    	   	$cookies{$key2} = $val2;                     # frames
    	   	$cookies{$key3} = ($key3) ? $val3 : "false"; # 7-bit
       	}
	} 

	%cookies;

} 

 
sub setCookie {
local ( $encoding, $frames, $bit7 ) = @_;
local ( $expires, $domain, $path );


	$frames  = "no"    if ( !$frames );
	$bit7    = "false" if ( !$bit7 );
 
	$prefs   = "geezsys=$encoding&frames=$frames&7-bit=$bit7";
	$expires = "Thu, 11-Nov-99 00:00:00 GMT";
	$domain  = ".ethiopiaonline.net";
	$path    = "/"; 

	"Set-Cookie: prefs=$prefs; expires=$expires; path=$path; domain=$domain\n\n";

}
#########################################################
# Do not change this, Do not put anything below this.
# File must return "true" value at termination
1;
##########################################################
