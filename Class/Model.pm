#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#
#
#   Class:          Model.pm
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
use Error qw(:try);

use Class::AccessPoint;
use Class::AccessPointProfile;

# global variables
#
my $configDir = $ENV{"HOME"} . "/.wireless_app";
my $iwlist = "/usr/sbin/iwlist";

##################
# public methods #
##################

# Model constructor.  Takes one parameter, the name of 
# a wireless network interface device.
#
sub new
{
   my ($class, $interface) = @_;
   my $this = {};
   
   # bless this object into given class 
   #
   bless $this, $class;

   # initialize all object variables
   #
   $this->{"interface"}    = $interface;
   $this->{"connectedAp"}  = "";
   $this->{"views"}        = (); # create empty array to store views
   $this->{"profiles"}     = {}; # create empty hash to store profiles
   $this->{"iwlist"}       = "";
   $this->{"config"}       = "";

   return $this;
}

sub init
{
   my ($I) = @_;

   # determine if the config directory exists or not
   #
   if(-d $configDir && -e "$configDir/config.xml")
   {
      # open configuration file and get config values
      #
      #my $dump = new XML::Dumper();
      #$I->{"config"} = $dump->xml2perl($configDir . "/config.xml");
      my $parser = new Data::DumpXML::Parser();
      #$I->{"config"} = $parser->parsefile($configDir . "/config.xml");

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
      $I->_generateDefaultConfig();
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
      throw Error::Simple("Given profile directory does not exist") unless(-d $profileDir);

      # directory has wrong read/write permissions
      #
      throw Error::Simple("Given profile directory does not have adequate read/write permissions") unless(-r $profileDir && -w $profileDir);
   }
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
   throw Error::Simple("Unable to locate linux wireless statistics application iwlist at '$iwlist', unable to proceed") unless(-e $iwlist);

   # scan for available wireless access points using iwlist
   # and capture results
   #
   my $cmd = $iwlist . " " . $I->{'interface'} . " scan";
   my $result = `$cmd` or throw Error::Simple("Scanning for wireless access points failed");

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
      $ap =~ /address\s?:\s?(.+)\n(.+)?essid\s?:\s?\"?(\w+)\"?\n/i;

      # address => essid
      #
      $Sid{$1} = $3;

      # parse data
      #
      my @BitRate;
      map { 

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
      } split("\n", $ap);
      $ApObject->set("bitRate", \@BitRate) if scalar @BitRate > 0;

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

# getAPs returns a hash containing address => essid key value pairs. This 
# method returns the data gathered during the previous scan.
#
sub getAPs
{
   my ($I) = @_;
   
   # if 'avaiable' variable isn't set, scan hasn't been called
   # perform scan and return results...
   #
   return $I->scan() if(not exists $I->{'apData'});
   
   my %Aps;
   my %Available = %{$I->{'apData'}};
   foreach my $ap (keys %Available)
   {
      $Aps{$ap} = $Available{$ap}{'essid'};
   }
   
   return %Aps;
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

# getDataByAddress takes one parameter, an AP address, and searches the 
# data gathered by scan for any matching data.
#
sub getDataByAddress
{
   my ($I, $address) = @_;

   # NOTE: need to verify given address!
   #

   $I->scan() if(not exists $I->{'apData'});

   return $I->{'apData'}{$address};
}

# getDataBySid takes one parameter, an ESSID, and searches the data
# gathered by scan for any matching data.
#
sub getDataBySid
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

   my $address = $I->{"connectedAp"};
   return $I->{"apData"}{$address};
}

sub getProfiles
{
   my ($I) = @_;

   return values( %{$I->{"profiles"}} );
}

sub getProfileDir
{
   my ($I) = @_;

   return $I->{"config"}{"profileDir"};
}

sub getStartupScript
{
   my ($I) = @_;

   return $I->{"config"}{"startupScript"};
}

sub setConnectedAP()
{
   my ($I, $address) = @_;

   if(grep{$address} $I->_getAddresses())
   {
      $I->{"connectedAp"} = $address;
   }
   else
   {
      print "error, the given address is not a valid access point.\n";
      die;
   }

   # notify all registered views that model has changed
   #
   $I->updateViews();
}

sub registerView
{
   my ($I, $view) = @_;

   push @{$I->{"views"}}, $view;
}

sub removeView
{
   my ($I, $view) = @_;

   my @Views = ();
   foreach my $current ( @{$I->{"views"}} )
   {
      push @Views, $current if($view != $current);
   }

   $I->{"views"} = @Views;
}

sub updateViews
{
   my ($I) = @_;

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

   if(exists $I->{"profiles"}{$name})
   {
      return delete($I->{"profiles"}{$name});
   }
}

sub importProfiles
{
   my ($I, $path) = @_;

   # given path doesn't exist or isn't a directory, return
   #
   throw Error::Simple("Given path does not exists or isn't a directory") unless(-d $path);
   
   # open directory and get list of file names
   #
   opendir(PROFILES, $path) or throw Error::Simple("Unable to open '$path' for import");
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
         throw Error::Simple("Failed parsing profile located at: '$path/$file'");
           
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
   throw Error::Simple("Given path does not exists or isn't a directory") unless(-d $path);
   
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
            throw Error::Simple("Unable to write profiles to '$path' for export");
         print PROFILES $xml;
         close(PROFILES);

         $count++;
      }

      # profile of that name does not exist!
      #
      else
      {
         throw Error::Simple("Profile '$name' does not exist");
      }
   }

   return $count;
}

# NOTE: Will need to add ability to scan currently connected access
# point to update data.  Several values may need to be frequently/semi-
# frequently updated.  This may be solved with one method or with several
# but at this point I don't know what data will be needed later on.

###################
# private methods #
###################

sub _loadProfiles
{
   my ($I, $path) = @_;
   
   # get the names of all files in the profileDir
   #
   opendir(PROFILES, $I->{"config"}{"profileDir"}) or 
      throw Error::Simple("Unable to open '" . $I->{"config"}{"profileDir"} . "' for import");
   my @files = readdir PROFILES;
   closedir(PROFILES);

   # if there are no files in the profile directory, exit method
   #
   return 1 if(scalar @files == 0);

   my $parser = new Data::DumpXML::Parser(Blesser => sub {});
   
   # loop through files and load xml data. Pass data through
   # Data::DumpXML::Parser object to get AccessPointProfile objects.
   #
   foreach my $file (@files)
   {
      next unless $file =~ /\.xml$/i;
      my $object = $parser->parsefile($I->{"config"}{"profileDir"} . "/" . $file) or
         throw Error::Simple("Failed parsing profile located at: '$path/$file'");

      # NOTE: Need to put check in to make sure that 2 profiles with
      # the same name aren't loaded or at least don't overwrite eachother
  
      # NOTE: when getting hash containing profile data, have to
      # manually bless reference into Class::AccessPointProfile.  
      # This must be done because the parser doesn't correctly do 
      # this when it parses the xml data.
      #
      my $profile = $$object[1];
      bless $profile, "Class::AccessPointProfile";

      $I->{"profiles"}{ $profile->get("name") } = $profile;
   }

   return 1;
}

sub _writeProfiles
{
   my ($I) = @_;
   
   foreach my $ap ($I->getProfiles())
   {
      # this profile does not need to be dumped
      # if it hasn't been modified
      #
      #next unless $ap->isModified();
      next unless($ap && $ap->isModified());
      
      # tidy up profile before dumping to disk...
      #
      $ap->clean();
      
      my $xml = Data::DumpXML->dump_xml($ap);
      my $file = $I->{"config"}{"profileDir"} . "/" . $ap->get("name") . ".xml";
      
      # write out xml to disk...
      #
      open(PROFILE, ">", $file) or throw Error::Simple("Unable to write profiles to '" . $I->{"config"}{"profileDir"} .  "' for export");
      print PROFILE $xml;
      close(PROFILE);
   }

   return 1;
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
   my ($I) = @_;

   # set default config values
   #
   my %config = (
      startupScript => "",
      profileDir => "$configDir/profiles",
      _dump => 1,
   );
   $I->{"config"} = \%config;
}

sub DESTROY
{
   my ($I) = @_;

   # if config file has changed, dump file to disk...
   #
   if(exists $I->{"config"}{"_dump"})
   {
      # set _dump to 0...
      #
      $I->{"config"}{"_dump"} = 0;
      
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
      open(CONFIG, ">", $configDir . "/config.xml") or throw ErrorSimple("Unable to write config file to disk");
      print CONFIG $xml;
      close(CONFIG);
   }

   # check if any profile objects have been changed, if yes
   # write them to disk.
   #
   $I->_writeProfiles();
}

1;#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#
