#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#
#
#   Class:          Class::Model
#
#   Author:         Kier Elliott
#
#   Date:           08/12/2004
#
#   Description:    The model class is responsible for gathering and
#                   storing all application data.  It is also 
#                   responsible for handling requests for that data
#                   by the application.
#
#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#
#
#   Subversion Info:
#     $LastChangedBy$
#     $Date$
#     $Rev$
#     $URL$
#
#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#

package Class::Model;

use strict; use warnings;
use XML::Dumper;
use Data::DumpXML;
use Data::DumpXML::Parser;

use Class::AccessPoint;
use Class::AccessPointProfile;
use Error::Exception;

# global variables
#
use constant TRUE => 1;
use constant FALSE => 0;

##################
# public methods #
##################

# Model constructor.  Takes one parameter, the name of 
# a wireless network interface device.
#
sub new
{
   my ($class, $configDir) = @_;
   my $this = {};
   
   # bless this object into given class 
   #
   bless $this, $class;

   # initialize all object variables
   #
   $this->{"interface"}    = "";
   $this->{"connectedAp"}  = "";
   $this->{"connected"}    = 0;
   $this->{"views"}        = (); # create empty array to store views
   $this->{"profiles"}     = {}; # create empty hash to store profiles
   $this->{"config"}       = {};
   $this->{"configDir"}    = $configDir;

   return $this;
}

sub init
{
   my ($I) = @_;

   # determine if the config directory exists or not
   #
   my $configDir = $I->{"configDir"};
   if(-d $configDir && -e "$configDir/config.xml")
   {
      # open configuration file and get config values
      #
      my $parser = new Data::DumpXML::Parser();

      # store hash created from config data in
      # config variable
      #
      my $data = $parser->parsefile($configDir . "/config.xml");
      $I->{"config"} = $$data[1];
   }
   else
   {
      # generate default config entries
      #
      $I->_generateDefaultConfig($configDir);
   }

   # determine if the given profile directory exists and has read/write
   # permission.  If not, throw error...
   #
   my $profileDir = $I->{"config"}{"profileDir"};
   if(-d $profileDir && -r $profileDir && -w $profileDir)
   {
      # load profiles into memory from current profile directory...
      #
      $I->_loadProfiles();
   }
   else
   {
      # directory doesn't exist
      #
      throw Error::FileSystemException("Given profile directory does not exist") unless(-d $profileDir);

      # directory has wrong read/write permissions
      #
      throw Error::FileSystemException("Given profile directory does not have adequate read/write permissions") unless(-r $profileDir && -w $profileDir);
   }

   # store location of config directory in config hash for later use
   #
   $I->{"configDir"} = $configDir;

   # perform a scan and look for available wireless access points...
   #
   $I->scan();

   # request new connection object be created...
   #
   Class::WirelessApp->getConnection();
}

# The scan method is the source of the models power.  This is where
# all data regarding Access Points (APs) is gathered, parsed and stored
# for later use by the application.  The method calls '/usr/sbin/iwlist'
# and parses the results.
#
# The scan method returns a hash consisting of the following data:
#   [
#     address => ApObject
#   ]
#
sub scan
{
   my ($I) = @_;
   
   print "Scanning...\n";
   
   # only proceed if iwlist is present on system...
   #
   throw Error::MissingResourceException("Unable to locate linux wireless statistics application iwlist at '" . $I->{"config"}{"utils"}{"iwlist"} . "', unable to proceed") unless(-e $I->{"config"}{"utils"}{"iwlist"});

   # scan for available wireless access points using iwlist
   # and capture results
   #
   my $cmd = $I->{"config"}{"utils"}{"iwlist"} . " " . $I->{'interface'} . " scan 2> /dev/null";
   my $result = `$cmd` or throw Error::ExecutionException("Scanning for wireless access points failed");

   $result =~ s/(^.+\n)//;
   $result =~ s/(^\s+)//;
   $result =~ s/(\n\s+)/\n/g;

   my @Points = split(/Cell\s\d+\s\-\s/i, $result);

   # the hash %Sid contains key => value pairs with each 
   # access points represented by a mac address => sid pair
   #
   my %Sid;

   # the hash %Aps contains key => value pairs with a
   # mac address for the key and a ApObject value
   #
   my %APs;

   # using results returned from iwlist, populate aps hash
   #
   foreach my $ap (@Points)
   {
      next unless $ap ne "";

      my $ApObject = new Class::AccessPoint();
      $ap =~ /address:\s?(.+)\n(.+)?essid:\s?\"?((\w\s?)+)\"?\n/i;

      # address => essid
      #
      $Sid{$1} = $3;

      # parse data for this access point...
      #
      $I->_parseScanData($ApObject, $ap);

      # address => data
      #
      $APs{$1} = $ApObject;
   }

   $I->{"apData"} = \%APs;

   # notify all registered views that model has changed
   #
   $I->updateViews();

   return %Sid;
}

sub scanConnectedAP
{
   my ($I, $interval) = @_;
   my %appConfigs = Class::WirelessApp->getConfig();
   $interval ||= 15000;

   # only attempt to scan if there is an active connection...
   #
   return FALSE unless $I->isConnected();

   print "Scanning for changes in Connected AP...\n";

   # scan connected ap and pipe results to scan.cache located in users config folder
   #
   #my $cmd = $I->{"config"}{"utils"}{"iwlist"} . " " . $I->{'interface'} . " scan > " . $I->{"configDir"} . "/scan.cache 2> /dev/null &";
   my $cmd = $I->{"config"}{"utils"}{"iwconfig"} . " " . $I->{'interface'} . " > " . $I->{"configDir"} . "/scan.cache 2> /dev/null &";
   system($cmd) == 0 or throw Error::ExecutionException("Scanning for wireless access points failed");

   # add new timeout to read scan results and update all data
   # regarding connected access point...
   #
   Glib::Timeout->add($interval, sub { $I->updateConnectedAP() });

   # must return true in order to ensure timeout will be executed again
   #
   return TRUE;
}

sub updateConnectedAP
{
   my ($I) = @_;
   
   print "Updating Connected AP...\n";

   # if cached text file containing scan results does not exist,
   # return false
   #
   return FALSE unless(-e $I->{"configDir"} . "/scan.cache");
   
   open(RESULTS, "<", $I->{"configDir"} . "/scan.cache");
   my $result = join "", <RESULTS>;
   close(RESULTS);
   
   $result =~ s/(^.+\n)//;
   $result =~ s/(^\s+)//;
   $result =~ s/(\n\s+)/\n/g;

#   my @Points = split(/Cell\s\d+\s\-\s/i, $result);
#
#   # using results returned from iwlist, populate aps hash
#   #
#   my $ApObject = $I->getConnectedAP();
#   foreach my $ap (@Points)
#   {
#      next unless($ap ne "" and $ap =~ /essid\s?\:\s?\"?$I->{"connectedAp"}\"?\s?/gi);
#
#      # parse data
#      #
#      $I->_parseScanData($ApObject, $ap);
#   }

   # parse data
   #
   $I->_parseScanData($I->getConnectedAP(), $result);

   # notify all registered views that model has changed
   #
   $I->updateViews();

   # remove calling timeout, data has been updated.  New timeout
   # will be created if connection remains active and new scan is performed
   # NOTE:  See Class::Model->scanConnectedAP for details
   #
   return FALSE;
}

sub getUtils
{
   my ($I) = @_;

   return %{ $I->{"config"}{"utils"} };
}

# getAPs returns a hash containing address => essid key value pairs. This 
# method returns the data gathered during the previous scan.  All available
# access points are returned, this includes multiple access points with the same
# name that are part of a greater wireless network.
#
sub getAvailableAPs
{
   my ($I) = @_;
   
   # if scan hasn't been called
   # perform scan...
   #
   $I->scan() if(not exists $I->{'apData'});
   
   my %Aps;
   my %Available = %{$I->{'apData'}};
   foreach my $ap (keys %Available)
   {
      $Aps{$ap} = $Available{$ap}{'essid'};
   }
   
   return %Aps;
}

sub getAvailableNetworks
{
   my ($I) = @_;

   # if scan hasn't been called
   # perform scan...
   #
   $I->scan() if(not exists $I->{'apData'});

   my @Aps = ();
   my %Available = %{$I->{"apData"}};
   foreach my $ap (keys %Available)
   {
      push @Aps, $Available{$ap}{"essid"};
   }

   return @Aps;
}

# getAPData returns a 2D hash containing all the information gathered by the 
# scan method.  The data is hashed with an address key and AccessPoint object value.
#
sub getAPData
{
   my ($I) = @_;

   $I->scan() if(not exists $I->{'apData'});

   return %{$I->{'apData'}};
}

# getAPByAddress takes one parameter, an AP address, and searches the 
# data gathered by scan for any matching data.
#
sub getAPByAddress
{
   my ($I, $address) = @_;

   # NOTE: need to verify given address!
   #
   
   $I->scan() if(not exists $I->{'apData'});

   return $I->{'apData'}{$address};
}

# getAPBySid takes one parameter, an ESSID, and searches the data
# gathered by scan for any matching data.
#
sub getAPBySid
{
   my ($I, $sid) = @_;

   # NOTE: need to verify given sid!
   #
   
   $I->scan() if(not exists $I->{'apData'});

   # parse through APs and return all AP data with given
   # AP name. Note: There can be more than one AP with
   # a given name!
   my @Aps;
   my %ApData = %{$I->{'apData'}};
   foreach my $addr (keys %ApData)
   {
      push @Aps, $ApData{$addr} if $ApData{$addr}->get('essid') eq $sid;
   }

   return @Aps;
}

sub getConnectedAP()
{
   my ($I) = @_;

   my $essid = $I->{"connectedAp"};
   my %Available = %{$I->{"apData"}};
   foreach my $ap (keys %Available)
   {
      return $Available{$ap} if($Available{$ap}{"essid"} eq $essid);
   }

   return undef;
}

sub getProfiles
{
   my ($I) = @_;

   return values( %{$I->{"profiles"}} );
}

sub getProfileBySid
{
   my ($I, $sid) = @_;
   
   foreach my $profile (keys %{$I->{"profiles"}} )
   {
      return $I->{"profiles"}{$profile} if($I->{"profiles"}{$profile}->get("essid") eq $sid);
   }

   return undef;
}

sub getProfileByAddress
{
   my ($I, $address) = @_;

   foreach my $profile (keys %{$I->{"profiles"}} )
   {
      return $I->{"profiles"}{$profile} if($I->{"profiles"}{$profile}->get("address") eq $address);
   }

   return undef;
}

sub getProfileByName
{
   my ($I, $name) = @_;
   
   foreach my $profile (keys %{$I->{"profiles"}} )
   {
      return $I->{"profiles"}{$profile} if($profile eq $name);
   }

   return undef;
}

sub getProfileDir
{
   my ($I) = @_;

   return $I->{"config"}{"profileDir"};
}

sub getInterface
{
   my ($I) = @_;

   return $I->{"config"}{"interface"};
}

sub setConnectedAP()
{
   my ($I, $name) = @_;

   if(grep{$name} $I->getAvailableNetworks())
   {
      $I->{"connectedAp"} = $name;
   }
   else
   {
      throw Error::IllegalParameterException("Cannot be connected to specified access point, does not exists or is not within range");
   }

   # create timeout to update connected ap data
   # NOTE: read about timeouts and idle calls in missing functions section
   # of Gtk2 Perl documentation at: http://gtk2-perl.sourceforge.net/doc/pod/Gtk2/api.html
   #
   Glib::Timeout->add(30000, sub { $I->scanConnectedAP() }) unless $I->{"connected"};

   # set connected flag to true
   #
   $I->{"connected"} = 1;

   # notify all registered views that model has changed
   # perform scan now to update data immediately
   #
   $I->updateViews();
}

sub isConnected
{
   my ($I) = @_;

   return $I->{"connected"};
}

sub setDisconnected
{
   my ($I) = @_;

   $I->{"connected"} = 0;
}

sub registerView
{
   my ($I, $view) = @_;

   push @{$I->{"views"}}, $view;
   print "registering new view!\n";
   print "registered views: " . scalar @{$I->{"views"}} . "\n";
}

sub removeView
{
   my ($I, $view) = @_;

   print "removing existing view!\n";
   my @Views = ();
   foreach my $current ( @{$I->{"views"}} )
   {
      push @Views, $current if($view != $current);
   }

   $I->{"views"} = scalar @Views > 0
      ? \@Views
      : [];
   print "remaining views: " . scalar @{$I->{"views"}} . "\n";
}

sub updateViews
{
   my ($I) = @_;

   print "updating all registered views!\n";

   foreach my $view ( @{$I->{"views"}} )
   {
      $view->update();
   }
}

sub createProfile
{
   my ($I, %data) = @_;

   if(not exists $I->{"profiles"}{ $data{"name"} })
   {
      # create new profile using given data...
      #
      my $profile = new Class::AccessPointProfile(%data);
      $profile->setModified(1);

      $I->{"profiles"}{ $profile->get("name") } = $profile;

      return $profile;
   }
}

sub destroyProfile
{
   my ($I, $name) = @_;

   # if profile exists, delete profile from
   # memory and in disk
   #
   if(exists $I->{"profiles"}{$name})
   {
#      # delete profile from disk...
#      #
#      my $file = $I->{"config"}{"profileDir"} . "/" . $name . ".xml";
#      unlink($file) if(-e $file);
   
      return delete($I->{"profiles"}{$name});
   }

   return undef;
}

sub importProfiles
{
   my ($I, $path) = @_;

   # given path doesn't exist or isn't a directory, return
   #
   throw Error::FileSystemException("Given path does not exists or isn't a directory") unless(-d $path);
   
   # open directory and get list of file names
   #
   opendir(PROFILES, $path) or throw Error::FileSystemException("Unable to open '$path' for import");
   my @Files = readdir PROFILES;
   closedir(PROFILES);

   return () if(scalar @Files == 0);

   # create new parser
   #
   my $parser = new Data::DumpXML::Parser(Blesser => sub {});

   foreach my $file (@Files)
   {
       next unless $file =~ /\.xml$/i;

       # pass file to parser and capture returned object data
       #
       my $object = $parser->parsefile($path . "/" . $file) or
         throw Error::ParsingException("Failed parsing profile located at: '$path/$file'");
           
       my $profile = $$object[1];
       bless $profile, "Class::AccessPointProfile";

       $I->{"_temp_profiles"}{ $profile->get("name") } = $profile;
   }

   return sort keys( %{$I->{"_temp_profiles"}} );
}

sub loadImportedProfiles
{
   my ($I, @Names) = @_;

   my %List = %{$I->{"_temp_profiles"}};
   my %Current = %{$I->{"profiles"}};
   foreach my $name (@Names)
   {
      # Check to make sure profile name is one of
      # those read by importProfiles
      #
      if(exists $List{$name})
      {
         my $i = 0;
         my $newName = $name;
         while(exists $Current{$newName})
         {
            $newName = $name . ++$i;
         }

         # update the profiles name to reflect new unique name
         #
         my $profile = $List{$name};
         $profile->set("name", $newName);
         $I->{"profiles"}{$newName} = $profile;
      }
   }

   # clear _temp_profile variable
   #
   delete $I->{"_temp_profiles"};
}

sub exportProfiles
{
   my ($I, $path, @Names) = @_;
   my $count = 0;

   # given path doesn't exists or isn't a directory, return
   #
   throw Error::FileSystemException("Given path does not exists or isn't a directory") unless(-d $path);
   
   my %Profiles = %{$I->{"profiles"}};
   foreach my $name (@Names)
   {
      if(exists $Profiles{$name})
      {  
         my $profile = $Profiles{$name};
         my $xml = Data::DumpXML->dump_xml($profile);
           
         # write xml data out to disk at given path
         #
         open(PROFILES, ">", $path . "/" . $profile->get("name") . ".xml") or 
            throw Error::FileSystemException("Unable to write profiles to '$path' for export");
         print PROFILES $xml;
         close(PROFILES);

         $count++;
      }

      # profile of that name does not exist!
      #
      else
      {
         throw Error::IllegalParameterException("Profile '$name' does not exist");
      }
   }

   return $count;
}

sub clean
{
   my ($I) = @_;
   my $configDir = $I->{"configDir"};

   # clean up model...
   #
   my $dump = $I->{"config"}{"_dump"} ||= 0;
   delete $I->{"config"}{"_dump"};

   # if config file has changed, dump file to disk...
   #
   if($dump)
   {
      # make sure config directory exists...
      #
      unless(-d $configDir)
      {
         print "Creating config directory at $configDir\n";
         mkdir($configDir);
         chmod(0711, $configDir);

         print "Creating profiles directory at " . $I->{"config"}{"profileDir"} . "\n";
         mkdir($configDir . "/profiles");
         chmod(0711, $I->{"config"}{"profileDir"});
      }
   
      # use Data::DumpXML object to generate the xml 
      # config file and write to disk
      #
      my $xml = Data::DumpXML->dump_xml($I->{"config"});

      # print out generated xml to config file...
      #
      open(CONFIG, ">", $configDir . "/config.xml") or throw Error::IOException("Unable to write config file to disk");
      print CONFIG $xml;
      close(CONFIG);
   }

   # check if any profile objects have been changed, if yes
   # write them to disk.
   #
   $I->_writeProfiles();

   # remove scan.cache file
   #
   unlink("$configDir/scan.cache");
}

# NOTE: Will need to add ability to scan currently connected access
# point to update data.  Several values may need to be frequently/semi-
# frequently updated.  This may be solved with one method or with several
# but at this point I don't know what data will be needed later on.

###################
# private methods #
###################

sub _parseScanData
{
   my ($I, $ApObject, $data) = @_;
   my @BitRate;

   map
   { 
      # THIS SECTION NEEDS TO BE REWORKED!
      #
      if($_ =~ /address\s?\:\s?(.+)\s?/i)
      {
         $ApObject->set("address", $1);
      }
      elsif($_ =~ /essid\s?\:\s?\"?(.+[^\"])\"?\s?/i)
      {
         $ApObject->set("essid", $1);
      }
      elsif($_ =~ /protocol\s?\:\s?(.+)\s?/i)
      {
         $ApObject->set("protocol", $1);
      }
      elsif($_ =~ /mode\s?\:\s?(.+)\s?/i)
      {
         $ApObject->set("mode", $1);
      }
      elsif($_ =~ /frequency\s?\:\s?(.+)\s?/i)
      {
         $ApObject->set("frequency", $1);
      }
      elsif($_ =~ /quality|signal\slevel|noise\slevel/i)
      {
         if($_ =~ /quality\s?\:\s?(\d+\/\d+)/i) { $ApObject->set("quality", $1); }
         if($_ =~ /signal\slevel\s?\:\s?(\-?\d+\sdbm)/i) { $ApObject->set("signalLevel", $1); }
         if($_ =~ /noise\slevel\s?\:\s?(\-?\d+\sdbm)/i) { $ApObject->set("noiseLevel", $1); }
      }
      elsif($_ =~ /encryption\skey\s?\:\s?(.+)\s?/i)
      {
         $ApObject->set("encryption", $1);
      }
      elsif($_ =~ /bit\srate\s?\:\s?((\d\.?)+)/i)
      {
         push @BitRate, $1;
      }
   } split("\n", $data);
   
   $ApObject->set("bitRate", \@BitRate) if scalar @BitRate > 0;
}

sub _loadProfiles
{
   my ($I, $path) = @_;
   
   # get the names of all files in the profileDir
   #
   opendir(PROFILES, $I->{"config"}{"profileDir"}) or 
      throw Error::FileSystemException("Unable to open '" . $I->{"config"}{"profileDir"} . "' for import");
   my @Files = readdir PROFILES;
   closedir(PROFILES);

   # if there are no files in the profile directory, exit method
   #
   return 1 if(scalar @Files == 0);

   my $parser = new Data::DumpXML::Parser(Blesser => sub {});
   
   # loop through files and load xml data. Pass data through
   # Data::DumpXML::Parser object to get AccessPointProfile objects.
   #
   foreach my $file (@Files)
   {
      next unless $file =~ /\.xml$/i;
      my $object = $parser->parsefile($I->{"config"}{"profileDir"} . "/" . $file) or
         throw Error::ParsingException("Failed parsing profile located at: '$path/$file'");

      # NOTE: Need to put check in to make sure that 2 profiles with
      # the same name aren't loaded or at least don't overwrite eachother
  
      # NOTE: when getting hash containing profile data, have to
      # manually bless reference into Class::AccessPointProfile.  
      # This must be done because the parser doesn't correctly do 
      # this when it parses the xml data.
      #
      my $profile = $$object[1];
      bless $profile, "Class::AccessPointProfile";

      # add profile to list and name => pointer pair to index
      #
      $I->{"profiles"}{ $profile->get("name") } = $profile;
   }
}

sub _writeProfiles
{
   my ($I) = @_;
   
   # get list of profiles in profileDir
   #
   opendir(PROFILES, $I->{"config"}{"profileDir"}) or 
      throw Error::FileSystemException("Unable to open '" . $I->{"config"}{"profileDir"} . "' for import");
   my %Files = map { $_ => $_ } readdir PROFILES;
   closedir(PROFILES);

   # remove '.' and  '..' from files list...
   #
   delete $Files{'.'};
   delete $Files{'..'};

   foreach my $ap ($I->getProfiles())
   {
      # first, remove current access point from
      # list of files in profile directory so it
      # won't get deleted!
      #
      delete $Files{$ap->get("name") . ".xml"};
   
      # this profile does not need to be dumped
      # if it hasn't been modified
      #
      next unless $ap->isModified();
      
      # tidy up profile before dumping to disk...
      #
      $ap->clean();
      
      my $xml = Data::DumpXML->dump_xml($ap);
      my $file = $I->{"config"}{"profileDir"} . "/" . $ap->get("name") . ".xml";
      
      # write out xml to disk...
      #
      open(PROFILE, ">", $file) or throw Error::IOException("Unable to write profiles to '" . $I->{"config"}{"profileDir"} .  "' for export");
      print PROFILE $xml;
      close(PROFILE);
   }

   # check files hash, any profile names still in the hash
   # have been removed by the user, delete file from disk
   #
   foreach my $file (keys %Files)
   {
      unlink($I->{"config"}{"profileDir"} . "/" . $file);
   }
}

sub _getAddresses
{
   my ($I) = @_;

   return keys %{$I->{"apData"}};
}

sub _getEssids
{
   my ($I) = @_;

   my @Names;
   while(my($key, $ap) = each( %{$I->{"apData"}} ))
   {
      push @Names, $ap->get("essid");
   }

   return @Names;
}

sub _generateDefaultConfig
{
   my ($I, $configDir) = @_;

   # determine the location of a few necessary utilities...
   #
   my $iwlist = `whereis -b iwlist`;
   my $iwconfig = `whereis -b iwconfig`;
   my $ifconfig = `whereis -b ifconfig`;
   my $dhcpcd = `whereis -b dhcpcd`;
   $iwlist =~ s/(.+)?\:\s(.+)?\n/$2/gi;
   $iwconfig =~ s/(.+)?\:\s(.+)?\n/$2/gi;
   $ifconfig =~ s/(.+)?\:\s(.+)?\n/$2/gi;
   $dhcpcd =~ s/(.+)?\:\s(.+)?\n/$2/gi;
   
   # verify that all the utilities are present on the system...
   #
   throw Error::MissingResourceException("Error: Unable to find utility 'iwlist'.  Unable to proceed!") unless($iwlist && $iwlist ne "");
   throw Error::MissingResourceException("Error: Unable to find utility 'iwconfig'.  Unable to proceed!") unless($iwconfig && $iwconfig ne "");
   throw Error::MissingResourceException("Error: Unable to find utility 'ifconfig'.  Unable to proceed!") unless($ifconfig && $ifconfig ne "");
   throw Error::MissingResourceException("Error: Unable to find utility 'dhcpcd'.  Unable to proceed!") unless($dhcpcd && $dhcpcd ne "");

   # try and determine the interface name
   # pipe all errors to /dev/null
   #
   `$iwconfig 2> /dev/null` =~ /^(\w+)\s/i;
   my $interface = $1;

   # set default config values
   #
   my %config = (
      profileDir => "$configDir/profiles",
      interface => $interface,
      utils => {
         iwlist => $iwlist,
         iwconfig => $iwconfig,
         ifconfig => $ifconfig,
         dhcpcd => $dhcpcd,
      },
      _dump => 1,
   );
   $I->{"config"} = \%config;
}

sub DESTROY
{
   my ($I) = @_;

   # if model data hasn't been dumped to disk
   # call clean method
   #
   $I->clean() if $I->{"config"}{"_dump"};
}

1;#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#
