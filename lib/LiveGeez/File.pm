package LiveGeez::File;


BEGIN
{
	use strict;
	use vars qw($VERSION $DIRMASK @itoa64 @gFile);

	$VERSION = '0.14';

	require 5.000;

	use LiveGeez::Local;
	use LiveGeez::HTML;

	if ( $processURLs ) {
		require LiveGeez::CacheAsSERA;
		use LWP::Simple;
	}
	#
	# Uncomment these next 3 if using getURL command
	#
	# use LWP::UserAgent;
	# use HTTP::Request;
	# use HTTP::Response;
	$DIRMASK = "0755";

	@itoa64 = split ( //, "./0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz" );
#
#  @gFile is a global array that holds the content of our file.  It is 
#         global since the number of subroutines that use it is high
#         enough that we should get a memory and performance enhancement
#         by not passing it around.
#
$#gFile = 100;	# preset to one hundred lines, most articles should be
		# smaller than this.
}




sub new
{
my $class   = shift;
my $request = shift;
my $self    = {};


	#
	# what else could we test for?
	#
	$request->{file} .= "/"
		if ( $request->{file} !~ /htm(l)?$/i && $request->{file} !~ /\/$/ );

	#
	# this isn't a good test, check the Content-Type type.
	#
	# $request->DieCgi ( "Unrecognized file type, does not appear to be HTML<br>$request->{file}" )
	# 	if ( $request->{file} !~ /htm(l)?$/i && $request->{file} !~ /\/$/ );

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
	$self->{fileSysOut} .= ".FirstTime"
				 if ( $request->{FirstTime} );

	my $blessing = bless $self, $class;

	$self->OpenFile;

	$blessing;

}


sub myRand
{
	my $rand = rand;
	$rand =~ s/0\.(\d{2})\d+/$1/;
	$rand %= 64;

        $itoa64[$rand];
}


#------------------------------------------------------------------------------#
#
# "OpenFile"
#
#   is here to do the dirty work of opening either a local or remote file and
#   copying the contents into the "gFile" array.  If the file is cached and
#   the file has not been modified the routine returns.  Otherwise document
#   data is copied into the htmlData hash field.  OpenFile has no return value.
#
#------------------------------------------------------------------------------#
sub OpenFile
{
my $self = shift;
my $file = $self->{request}->{file};
my ( $sourceFile, $fileStream, $fileIsURL );


	#
	# check if file is a URL, if not strip off leading "/" if any.
	#
	$file =~ s#^/##
	unless ( ($fileIsURL = ( $file =~ m#^(\w)+://# )) );


	#
	# if we do not permit remote processing then bail at this point.
	# ...or we could redirect to Zobel server that does allow remote
	# processing...
	#
	$self->{request}->DieCgi ( "Sorry!  Zobel at $scriptURL is for local use only!\n" )
		if ( $fileIsURL && !$processURLs );

	$self->{isRemote} = $fileIsURL;

	#
	# check if cached.
	#
	$sourceFile = ( $fileIsURL ) ? $self->CheckCacheURL : $self->CheckCacheFile;

	$self->{request}->DieCgiWithEMail ( "The requested file '$self->{request}->{file}' was not found.", "$self->{request}->{file} not found" )
		unless ( $sourceFile );

	#
	# if cached delete or return
	#
	return if ( $self->{isCached} );


	#
	# otherwise read file into our "@gFile" buffer;
	#
	$fileStream = ($self->{isZipped}) ? "gzip -d --stdout $sourceFile |" : "$sourceFile";

	open (FILE, "$fileStream") || $self->{request}->DieCgi
	     ( "!: Could Not Open File: $sourceFile!\n" );

	#
	# cute one-liner but turns out to be inefficient because the string has
	# to grow with each new line read, so we use a package-local presized array.
	#
	# $self->{htmlData} = join ( "", <FILE> );

	@gFile = <FILE>;
	$self->{htmlData} = join ( "", @gFile );

	close ( FILE );

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
	elsif ( $self->{useSource} ) {
	 	$self->{request}{'x-gzip'} = 0;
	 	$self->{request}->HeaderPrint;
	 	$self->{request}->print ( $self->{htmlData} );
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

	$#gFile = -1;
	delete ( $self->{htmlData} );
}


#------------------------------------------------------------------------------#
#
# "DisplayFileAndCache"
# 
#	Does just as the name implies.  The "cacheFileIn" string must be set
#	before the method is called.  The "htmlData" is written into a tee pipe
#	to simultaneously display the output and write to a file (cacheFileIn
#	that is).  The cached file is finally gzipped unless it is a frame
#	element that we want users to cache on their side (in which case we
#	require frame elements to be stored in a "Frames" subdirectory).
#
#------------------------------------------------------------------------------#
sub DisplayFileAndCache
{
my $self = shift;
my $cacheFile = $self->{cacheFileIn};


	$self->{request}->{'x-gzip'} = 0;
	$self->{request}->HeaderPrint;
	if ( $useApache ) {
		$self->{request}->{apache}->print ( $self->{htmlData} );
		open (CACHEFILE, ">$cacheFile") 
		|| $self->{request}->DieCgi ( "!: Can't Open $cacheFile!\n" );
	}
	else {
		open (CACHEFILE, "| tee $cacheFile") 
		|| $self->{request}->DieCgi ( "!: Can't Open $cacheFile!\n" );
	}
	print CACHEFILE $self->{htmlData};
	close (CACHEFILE);

	system ( 'gzip', '-f', $cacheFile ) if ( $cacheFile !~ /\/Frames/ );

	1;
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
my ( $url, $cacheDate ) = @_;
my $responseCode;


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
#	Checks to see if a cached version of a file in a request output system
#	is available.  If so isCached and cacheFileOut are set.  If the "no-cache"
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
my $diskFile = $self->{request}->{file};
my ( $dir, $file, $cacheDir, $cacheFileIn, $cacheFileOut, $sourceFile, $ext );


	($file, $dir) = split ( m#/#, reverse($diskFile), 2 );
	$dir = reverse($dir);
	$dir =~ s|^/||;

	if ( $file ) {
		$file = reverse($file);
		$file =~ s/[ ()]/_/g;
	}
	else {
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

	#
	#  Alas the sourceFile that we are working with
	#
	$sourceFile = "$webRoot/$diskFile";

	unless ( (-e $sourceFile) ) {
		if ( (-e "$sourceFile.gz") ) {
			$self->{isZipped} = "true";
			$sourceFile .= ".gz";
		}
		else {
			return undef;
		}
	}

	#
	#  Alas the sourceFile that we are working with
	#
	if ( $self->{request}->{sysIn}->{sysName} eq $self->{request}->{sysOut}->{sysName} ) {
		$self->{useSource} = 1;
		return ( $self->{sourceFile} = $sourceFile );
	}

	$self->{baseDomain} = "$dir" if ( $dir );

	$file =~ s/\.(htm(l)?)$//oi;
	$ext  =  $1;
	$file =~ s/\.sera$//i;

	$dir          =~ s/[ ()]/_/g;
	$cacheDir     = "$FileCacheDir/$dir";
	$cacheFileIn  = "$cacheDir/$file.$self->{fileSysOut}.$ext";
	$cacheFileOut =  ( $diskFile !~ /\/Frames/ )
	              ? "$cacheDir/$file.$self->{fileSysOut}.$ext.gz"
	              :  $cacheFileIn
	              ;

	$self->{cacheFileIn} = $cacheFileIn;

	unlink ( $cacheFileOut ) if ( $self->{request}->{'no-cache'} );

	if ( (-e $cacheFileOut) ) {
		#
		#  Check Date Here
		#
		if ( $checkFileDates
			 && ( (stat ( $cacheFileOut ))[9] < (stat ( $sourceFile ))[9] ) )
	 	{
			#
			#  if old delete and get New
			#
			unlink <$cacheDir/$file*.gz>;

			#
			#  is sourceFile in SERA?
			#
			$sourceFile = LiveGeez::CacheAsSERA::HTML ( $self, $sourceFile )
				unless ( $self->{request}->{sysIn}->{sysName} eq "sera" );
		}
		else {
			$sourceFile = $cacheFileOut;
			$self->{isCached} = "true";
			$self->{isZipped} = "true" if ( $cacheFileOut ne $cacheFileIn );
		}
		$self->{cacheFileOut} = $cacheFileOut;
	}
	else {
		MakeCacheDir ($cacheDir, $FileCacheDir);
		#
		#  is sourceFile in SERA?
		#
		$sourceFile = LiveGeez::CacheAsSERA::HTML ( $self, $sourceFile )
			unless ( $self->{request}->{sysIn}->{sysName} eq "sera" );
	}

	$self->{sourceFile} = $sourceFile;

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
my $URL  = $self->{request}->{file};
my ( $proto, $url, $dir, $file, $cacheDir, $cacheFileIn, $cacheFileOut, $ext, $baseURL );


	($proto,$url) = split ( m#//#, $URL, 2 );
	($url,  $dir) = split ( m#/#, $url, 2 );
	($file, $dir) = split ( m#/#, reverse($dir), 2 );

	chop ($proto);
	$dir = reverse($dir);
	$url = lc($url);
	$baseURL = "$proto://$url/$dir/";
	$self->{baseDomain}  = "$proto://$url/";
	$self->{baseDomain} .= "$1" if ( $dir =~ /^(~[^\/]+)/ );

	if ( $file ) {
		$file = reverse($file);
		$file =~ s/[ ()]/_/g;
	}
	else {
		# we were passed a directory reference
		# so for caching purposes we'll use "index.html"
		$file = "index.html";
	}

	$dir        =~ s/[ ()]/_/g;
	$cacheDir   = "$URLCacheDir/$url/$dir";
	$sourceFile = "$cacheDir/$file";

	$file       =~ s/\.(htm(l)?)$//oi;
	$ext        =  $1;
	$file       =~ s/\.sera$//i;

	$cacheFileIn         = "$cacheDir/$file.$self->{fileSysOut}.$ext";
	$cacheFileOut        = "$cacheDir/$file.$self->{fileSysOut}.$ext.gz";

	$self->{baseURL}     = $baseURL;
	$self->{cacheFileIn} = $cacheFileIn;

	unlink <$cacheDir/$file*>
		if ( $self->{request}->{'no-cache'} );
	printf STDERR "Clear Cache Error [$!]\n" if ( $! );

	#
	# If the file is cached we will compare the file date against the
	# version on the server
	#
	if (-e $cacheFileOut) {
		# my ($mtime) = (stat($cacheFileOut))[9];
		# my ($cacheDate) = HTTP::Date::time2str($mtime);

		my $rc = mirror ($URL, $sourceFile);
		if ( $rc == RC_OK ) {
			# Clear cache
			my $output = unlink <$cacheDir/$file*gz>;
			
			# We start anew...
			#
			# Don't gzip sourceFiles from URLs,since it complicates the
			# use of "mirror" (we would have to ungzip the file).  We
			# like "mirror" for now because it does error checking, we
			# might write our own version later...
			#
			# system ( 'gzip', $sourceFile );

			#
			#  is sourceFile in SERA?
			#
			$sourceFile = LiveGeez::CacheAsSERA::HTML ( $self, $sourceFile )
				unless ( $self->{request}->{sysIn}->{sysName} eq "sera" );

			return ( $self->{sourceFile} = $sourceFile );
		}
		elsif ( $rc != RC_NOT_MODIFIED ) {
			return undef;
		}

		# Use present cache file, we assume a 304
		$self->{isZipped} = $self->{isCached} = "true";
		$self->{cacheFileOut} = $sourceFile = $cacheFileOut;
	
	}
	else {
		use POSIX qw(strftime);

		my $tempFile = "$URLCacheDir/tmp."
		             . strftime ( '%m%d%H%M%S', localtime(time) )
		             . "."
		             # . myRand
			     . rand
		             ;
		if ( mirror ($URL, $tempFile) == RC_OK ) {
			MakeCacheDir ($cacheDir, $URLCacheDir);
			rename ( $tempFile, $sourceFile );
			#
			#  is sourceFile in SERA?
			#
			$sourceFile = LiveGeez::CacheAsSERA::HTML ( $self, $sourceFile )
				unless ( $self->{request}->{sysIn}->{sysName} eq "sera" );
		}
		else {
			return undef;
		}
	}

	$self->{sourceFile} = $sourceFile;

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
my ($cacheDir, $refDir) = @_;  # always starts with "/";

	unless ( (-e $cacheDir) ) {
		$cacheDir    =~ s/^$webRoot//;
		$cacheDir    =~ s|^/||;

		my $fullPath = $webRoot;
		my (@dirs) = split ( /\//, $cacheDir );

		foreach my $dir ( @dirs ) {
			$fullPath .= "/$dir";
			if ( !(-e $fullPath) ) {
				warn ( "Failed to make '$fullPath' [$cacheDir]: $!" ) unless ( mkdir ($fullPath, 0755) );
			}
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
my $cacheFile = $self->{cacheFileOut};


	if ( $ENV{HTTP_ACCEPT_ENCODING} =~ "gzip" 
	     && $ENV{HTTP_USER_AGENT} !~ "MSIE" ) {
	     	$self->{request}->{'x-gzip'} = 1;
		open ( FILE, "$cacheFile" ) || $self->{request}->DieCgi
		 ( "!: Could Not Open Cached File: $cacheFile!\n" );
	}
	else {
		my $fileStream 
		= ( ( $self->{isZipped} && $self->{request}->{'x-gzip'}) || !$self->{isZipped} )
		  ? "$cacheFile"
		  : "gzip -d --stdout $cacheFile |"
		;

		open ( FILE, "$fileStream" ) || $self->{request}->DieCgi
			 ( "!: Could Not Open Cached File: $cacheFile!\n" );

	}

	$self->{request}->HeaderPrint;

	$self->{request}->print ( <FILE> );

	close (FILE);

     	$self->{request}->{'x-gzip'} = 0;
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
my $cacheFile = $self->{cacheFileOut};
my $fileStream;


	$fileStream = ($self->{isZipped}) ? "gzip -d --stdout $cacheFile |" : "$cacheFile";

	open (FILE, "$fileStream") || $self->{request}->DieCgi
	     ( "!: Could Not Open Cached File: $cacheFile!\n" );
	@gFile = <FILE>;
	$self->{htmlData} = join ( "", @gFile );
	close (FILE);

}


sub SaveToCache
{
my $self = shift;
my $cacheFile = $self->{cacheFileIn};


	if ( $useApache ) {
		$self->{request}->{apache}->print ( $self->{htmlData} );
		open (CACHEFILE, ">$cacheFile") 
		|| $self->{request}->DieCgi ( "!: Can't Open $cacheFile!\n" );
	}
	else {
		open (CACHEFILE, "| tee $cacheFile")
		|| $self->{request}->DieCgi ( "!: Can't Open $cacheFile!\n" );
	}
	print CACHEFILE $self->{htmlData};
	close (CACHEFILE);

	system ( 'gzip', '-f', $cacheFile ) if ( $cacheFile !~ /\/Frames/ );

}


sub show
{
my $self = shift;


	foreach $key (keys %$self) {
		if ( ref $self->{$key} ) {
			$self->{$key}->show;
		}
		else {
			$self->{request}->print ( "  $key = $self->{$key}\n" );
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

 use LiveGeez::Request;
 use LiveGeez::File;

 main:
 {

 	my $r = LiveGeez::Request->new;

	my $f = LiveGeez::File->new ( $r );

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