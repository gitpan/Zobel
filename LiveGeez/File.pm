package LiveGeez::File;

require 5.000;

use Convert::Ethiopic::Cstocs;
use LiveGeez::Local;
use LiveGeez::HTML;
use LWP::Simple;
#
# Uncomment these next 3 if using getURL command
#
# use LWP::UserAgent;
# use HTTP::Request;
# use HTTP::Response;


#
#  @gFile is a global array that holds the content of our file.  It is 
#         global since the number of subroutines that use it is high
#         enough that we should get a memory and performance enhancement
#         by not passing it around.
#
local ( @gFile );
$#gFile = 100;	# preset to one hundred lines, most articles should be
				# smaller than this.


sub new
{
my $class = shift;
my $request = shift;
my $self = {};


	$request->{file} .= "/"
	    if ( $request->{file} !~ /\.(\w+)$/ && $request->{file} !~ /\/$/ );


	CgiDie ( "Unrecognized file type, does not appear to be HTML<br>$request->{file}" )
		if ( $request->{file} !~ /htm(l)?$/ && $request->{file} !~ /\/$/ );

	$self->{request}     =   $request;

	$self->{fileSysOut}  =   $request->{sysOut}->{sysName};
	$self->{fileSysOut} .= ".$request->{sysOut}->{xfer}"
							 if ( $request->{sysOut}->{xfer} ne "notv" );
	$self->{fileSysOut} .= ".7-bit"
							 if ( $request->{sysOut}->{'7-bit'} );
	$self->{fileSysOut} .= ".$request->{sysOut}->{options}"
							 if ( $request->{sysOut}->{options} );
	$self->{fileSysOut} .= ".$request->{sysOut}->{lang}";
	$self->{fileSysOut} .= ".NoFrames"
							 if ( $request->{frames} eq "no" );

	my $blessing = bless $self, $class;

    $self->OpenFile;

    return ( $blessing );

}


#------------------------------------------------------------------------------#
#
# "OpenFile"
#
#	is here to do the dirty work of opening either a local or remote file and
#	copying the contents into the "gFile" array.  If the file is cached and
#	the file has not been modified the routine returns.  Otherwise document
#   data is copied into the htmlData hash field.  OpenFile has no return value.
#
#------------------------------------------------------------------------------#
sub OpenFile
{
my $self = shift;
local ( $file ) = $self->{request}->{file};
local ( $sourceFile, $fileStream, $fileIsURL );


	#
	# check if file is a URL, if not strip off leading "/" if any.
	#
	$file =~ s#^/##
    	unless ( ($fileIsURL = ( $file =~ m#^(\w)+://# )) );


	#
	# check if cached.
	#
	$sourceFile = ( $fileIsURL ) ? $self->CheckCacheURL : $self->CheckCacheFile;


	#
	# if cached delete or return
	#
	return if ( $self->{isCached} );


	#
	# otherwise read file into our "@gFile" buffer;
	#
	$fileStream = ($self->{isZipped}) ? "gzip -d --stdout $sourceFile |" : "$sourceFile";

	open ( FILE, "$fileStream" ) || CgiDie ( "!: Could Not Open File: $sourceFile!\n" );


	#
	# cute one-liner but turns out to be inefficient because the string has
	# to grow, so we use a package-local presized array.
	#
	# $self->{htmlData} = join ( "", <FILE> );

	@gFile = <FILE>;
	$self->{htmlData} = join ( "", @gFile );

    close ( FILE );

	return;
}


sub Display
{
my $self = shift;


	#
	# If cached, display and return.
	#
	if ( $self->{isCached} ) {
		$self->DisplayFromCache;
		return;
	}


	#
	# Translate buffer.
	#
	FileBuffer ($self);


	#
	# finally, display and cache the results.
	#
	$self->DisplayFileAndCache;


	return;
}


#------------------------------------------------------------------------------#
#
# "DisplayFileAndCache"
# 
#	Does just as the name implies.  The "cacheFileIn" string must be set
#	before the method is called.  The "htmlData" is written into a tee pipe
#	to simultaneously display the output and write to a file (cacheFileIn
#   that is).  The cached file is finally gzipped unless it is a frame
#	element that we want users to cache on their side (in which case we
#   require frame elements to be stored in a "Frames" subdirectory).
#
#------------------------------------------------------------------------------#
sub DisplayFileAndCache
{
my $self = shift;
local ($cacheFile) = $self->{cacheFileIn};

	print PrintHeader if ( !$self->{request}->{HeaderPrinted} );
    open (CACHEFILE, "| tee $cacheFile") 
    	  || CgiDie ("!: Can't Open $cacheFile!\n");
	print CACHEFILE $self->{htmlData};
	close (CACHEFILE);

	system ( 'gzip', $cacheFile ) if ( $cacheFile !~ /\/Frames/ );

}


#------------------------------------------------------------------------------#
#
# "getURL"
#
#	is just here now occassional debugging purposes.  It is not an essential
#	part of solving the task at hand since we have elected to use the Request
#	"mirror" function which does nearly the same thing but with better error
#	handling.
#
#------------------------------------------------------------------------------#
sub getURL
{
my $self = shift;
local ( $url, $cacheDate ) = @_;
local ( $responseCode );


	my $ua = new LWP::UserAgent;
	$ua->agent ("Ge'ezilla/0.1");
	my $request = new HTTP::Request ('GET', $url);
	$request->header ('If-Modified-Since' => $cacheDate) if ( $cacheDate );
	my $response = $ua->request ($request);

	if ( ($responseCode = $response->code) != 304 && !$response->is_success ) {
		print $response->error_as_HTML;
		exit (0);
	}

	@gFile = $response->content if ( $responseCode != 304 );
	$self->{htmlData} = join ( "", @gFile );

	undef ($ua);
	undef ($response);
	undef ($request);

	return ( $responseCode == 304 ) ? 1 : 0;

}


#------------------------------------------------------------------------------#
#
# "CheckCacheFile"
#
#   Checks to see if a cached version of a file in a request output system
#   is available.  If so isCached and cacheFileOut are set.  If the "no-cache"
#	pragma is set cacheFileOut will be deleted.  isZipped is set for compressed
#	cached files.  cacheFileIn is set as a pre-zipped storage name for zipped
#	files for uncached files.  sourceFile always points to the file to be
#	opened, cached or uncached.  MakeCacheDir is called to create an appropriate
#	subdirectory to store files in cache.  The sourceFile is returned.
#
#	Note: Cached file dates are _not_ compared to the source file dates simply
#	to save the time involved for the operations required.  This does not
#	present a problem for the way files are updated at the ENH and Tobia where
#	cached version are cleaned out when new source versions are installed.
#
#------------------------------------------------------------------------------#
sub CheckCacheFile
{
my $self = shift;
local ( $diskFile ) = $self->{request}->{file};
local ( $dir, $file, $cacheDir, $cacheFileIn, $cacheFileOut, $sourceFile, $ext );


	($file,$dir) = split ( m#/#, reverse($diskFile), 2 );
	$dir  = reverse($dir);

	#------------------------------------BEGIN TEST----------
	if ( $file ) {
		$file = reverse($file);
	} else {
		# we were passed a directory reference
		# so for caching purposes we'll use "index.html"
		if ( -e ("$webRoot/$diskFile/index.html") ) {
			$diskFile .= "/index.html";
		} elsif ( -e ("$webRoot/$diskFile/index.htm") ) {
			$diskFile .= "/index.htm";
		} elsif ( -e ("$webRoot/$diskFile/index.sera.html") ) {
			$diskFile .= "/index.sera.html";
		}
		$file = "index.html";
	}

	$self->{baseDomain} = "$dir" if ( $dir );
	#------------------------------------END TEST------------

	$file =~ s/\.(htm(l)?)$//o;
	$ext  =  $1;
	$file =~ s/\.sera$//;

	$cacheDir     = "$FileCacheDir/$dir";
	$cacheFileIn  = "$cacheDir/$file.$self->{fileSysOut}.$ext";
	$cacheFileOut =  ( $diskFile !~ /\/Frames/ )
	              ? "$cacheDir/$file.$self->{fileSysOut}.$ext.gz"
	              :  $cacheFileIn
	              ;

	$self->{cacheFileIn} = $cacheFileIn;

	unlink ( $cacheFileOut ) if ( $self->{request}->{'no-cache'} );

    #
    #  Return Cached File name if found, we don't do date tests for now...
    #
	if ( (-e $cacheFileOut) ) {
		$self->{isCached}     = "true";
		$self->{isZipped}     = "true" if ( $cacheFileOut ne $cacheFileIn );
		$self->{cacheFileOut} = $sourceFile = $cacheFileOut;
	} else {
		MakeCacheDir ($cacheDir);
		$sourceFile = "$webRoot/$diskFile";
	    if ( (-e "$webRoot/$FILE.gz") ) {
	    	$self->{isZipped} = "true";
			$sourceFile .= ".gz";
		}
	}

	return ( $self->{sourceFile} = $sourceFile );

}


#------------------------------------------------------------------------------#
#
# "CheckCacheURL"
# 
#	is the analog of CheckCacheFile with the ability to open a URL and update
#	local cached copies when out of date.
#
#------------------------------------------------------------------------------#
sub CheckCacheURL
{
my $self = shift;
local ( $URL ) = $self->{request}->{file};
local ( $proto, $url, $dir, $file, $cacheDir, $cacheFileIn, $cacheFileOut, $ext, $baseURL );


	($proto,$url) = split ( m#//#, $URL, 3 );
	($url,  $dir) = split ( m#/#, $url, 2 );
	($file, $dir) = split ( m#/#, reverse($dir), 2 );

	chop ($proto);
	$dir  = reverse($dir);
	$baseURL = "$proto://$url/$dir/";
	$self->{baseDomain} = "$proto://$url/$1" if ( $dir =~ /^(~[^\/]+)/ );

	if ( $file ) {
		$file = reverse($file);
	} else {
		# we were passed a directory reference
		# so for caching purposes we'll use "index.html"
		$file = "index.html";
	}

	$cacheDir   = "$URLCacheDir/$url/$dir";
	$sourceFile = "$cacheDir/$file";

	$file       =~ s/\.(htm(l)?)$//o;
	$ext        =  $1;
	$file       =~ s/\.sera$//;

	$cacheFileIn         = "$cacheDir/$file.$self->{fileSysOut}.$ext";
	$cacheFileOut        = "$cacheDir/$file.$self->{fileSysOut}.$ext.gz";

	$self->{baseURL}     = $baseURL;
	$self->{cacheFileIn} = $cacheFileIn;

	unlink <$cacheDir/$file*>
		if ($self->{request}-{'no-cache'});
	#
	# If the file is cached we will compare the file date against the version
	# on the server
	#
	if (-e $cacheFileOut) {
		# my ($mtime) = (stat($cacheFileOut))[9];
		# my ($cacheDate) = HTTP::Date::time2str($mtime);

		if ( mirror ($URL, $sourceFile) == 200 ) {
			# Clear cache
			unlink <$cacheDir/$file*.gz>;
			# We start anew...
			#
			# Don't gzip sourceFiles from URLs,since it complicates the
			# use of "mirror" (we would have to ungzip the file).  We
			# like "mirror" for now because it does error checking, we
			# might write our own version later...
			#
			# system ( 'gzip', $sourceFile );
			return ( $self->{sourceFile} = $sourceFile );
		}

		# Use present cache file, we assume a 304
		$self->{isZipped} = $self->{isCached} = "true";
		$self->{cacheFileOut} = $sourceFile = $cacheFileOut;
	
	} else {
		MakeCacheDir ($cacheDir);
		mirror ($URL, $sourceFile);
	}

	return ( $self->{$sourceFile} = $sourceFile );

}


#------------------------------------------------------------------------------#
#
# "MakeCacheDir"
# 
#	Does just as the name implies.  The "$cacheDir" path is received as the 
#	sole argument.  MakeCacheDir will create the subdirectories in the cacheDir
#	path as needed.  This is a naive apporoach to caching but we can live
#	with it for now...
#
#------------------------------------------------------------------------------#
sub MakeCacheDir
{
local ( $cacheDir ) = shift;


	if ( !(-e $cacheDir) ) {
		my (@dirs) = split ( /\//, $cacheDir );
		my ($dir, $fulldir); 
		foreach $dir ( @dirs ) {
			$fullDir = ($fullDir) ? "$fullDir/$dir" : $dir;
			mkdir ($fullDir, 0755) if ( !(-e $fullDir) );
		}
	}

}


#------------------------------------------------------------------------------#
#
# "DisplayFromCache"
# 
#	Does just as the name implies.  The "cacheFileOut" string must be set
#	before the method is called.  The file is printed to STDOUT.  Generally
#   cached files are gzipped, DisplayFromCache will gunzip as needed.
#
#------------------------------------------------------------------------------#
sub DisplayFromCache
{
my $self = shift;
local ( $cacheFile ) = $self->{cacheFileOut};
local ( $fileStream );

	#  Avoid extra test and die on Open if we don't exist.
	#
	# CgiDie ("!: Requested File: $cacheFile Not Found!\n") if ( !(-e $cacheFile) );

	print PrintHeader if ( !$self->{request}->{HeaderPrinted} );
	$fileStream = ($self->{isZipped}) ? "gzip -d --stdout $cacheFile |" : "$cacheFile";

	open ( FILE, "$fileStream" ) || CgiDie ("!: Could Not Open Cached File: $cacheFile!\n");
	print <FILE>;
    close (FILE);

}


#------------------------------------------------------------------------------#
#
# "ReadFromCache"
# 
#	Does just as the name implies.  The "cacheFileOut" string must be set
#	before the method is called.  Generally cached files are gzipped,
#   ReadFromCache will gunzip as needed.
#
#------------------------------------------------------------------------------#
sub ReadFromCache
{
my $self = shift;
local ( $cacheFile ) = $self->{cacheFileOut};
local ( $fileStream );


	# CgiDie ("!: Requested File: $cacheFile Not Found!\n") if ( !(-e $cacheFile) );

	$fileStream = ($self->{isZipped}) ? "gzip -d --stdout $cacheFile |" : "$cacheFile";

	open ( FILE, "$fileStream" ) || CgiDie ("!: Could Not Open Cached File: $cacheFile!\n");
	@gFile = <FILE>;
	$self->{htmlData} = join ( "", @gFile );
    close (FILE);

}


sub SaveToCache
{
my $self = shift;
local ($cacheFile) = $self->{cacheFileIn};

    open (CACHEFILE, "| tee $cacheFile") 
    	  || CgiDie ("!: Can't Open $cacheFile!\n");
	print CACHEFILE $self->{htmlData};
	close (CACHEFILE);

	system ( 'gzip', $cacheFile ) if ( $cacheFile !~ /\/Frames/ );

}


sub show
{
my ( $self ) = shift;

	foreach $key (keys %$self) {
		if ( ref $self->{$key} ) {
			$self->{$key}->show();
		}
		else {
			print "  $key  = $self->{$key}\n";
		}
	}

}
#########################################################
# Do not change this, Do not put anything below this.
# File must return "true" value at termination
1;
##########################################################


__END__


=head1 NAME

LiveGeez::File - File Openning and Caching for LiveGe'ez

=head1 SYNOPSIS

 use LiveGeez::Local;
 use LiveGeez::Request;
 use LiveGeez::File;

 main:
 {
 local ( %input );
 local ( $r ) = LiveGeez::Request->new;


	ReadParse ( \%input );
	$r->ParseInput ( \%input );
	my ( $f ) = LiveGeez::File->new ( $r );
	$f->Display;

	exit (0);

 }

=head1 DESCRIPTION

File.pm instantiates an object for processing an Ethiopic text or HTML
document.  The constructor requires a LiveGeez::Request object as an
argument.

=head1 AUTHOR

Daniel Yacob,  L<LibEth@EthiopiaOnline.Net|mailto:LibEth@EthiopiaOnline.Net>

=head1 SEE ALSO

S<perl(1).  Ethiopic(3).  L<http://libeth.netpedia.net/LiveGeez.html|http://libeth.netpedia.net/LiveGeez.html>>

=cut
