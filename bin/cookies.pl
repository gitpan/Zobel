#!/usr/bin/perl

require "/home/enh/HTML/cgi/cgi-lib.pl";

# %thecookies = &getCookies();
# $thecookies{'geezsys'};

sub getCookies {
	# cookies are seperated by a semicolon and a space, this will split
	# them and return a hash of cookies
	local(@rawCookies) = split (/; /,$ENV{'HTTP_COOKIE'});
	local(%cookies);

	foreach(@rawCookies){
	    ($trash, $key1, $val, $val2) = split (/=/,$_);
		 ($val1, $key2) = split(/&/,$val);
        $cookies{$key1} = $val1;
        $cookies{$key2} = $val2;
	} 

	return %cookies; 
} 
 
sub setCookie{
	local ($encoding, $frames) = @_;
	$frames = "no" if ( !$frames );
 
	local ($name, $value, $expires, $domain, $path);
	$name = "geezsys";
	$value = $encoding;
        $expires = "Thu, 11-Nov-99 00:00:00 GMT";
        $domain  = ".ethiopiaonline.net";
        $path    = "/"; 

	return "Set-Cookie: prefs=$name=$value&frames=$frames; expires=$expires; path=$path; domain=$domain\n\n";
}
