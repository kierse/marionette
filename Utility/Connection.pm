#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#
#
#   Class:          Utility::Connection
#
#   Author:         Kier Elliott
#
#   Date:           09/07/2004
#
#   Description:    
#
#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#
#
#   Subversion Info:
#     $LastChangedBy: kierse $
#     $Date: 2004-09-03 22:46:23 -0600 (Fri, 03 Sep 2004) $
#     $Rev: 11 $
#     $URL: svn+ssh://zeus/var/svn/wireless_app/trunk/Class/MainView.pm $
#
#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#

package Utility::Connection;

use strict; use warnings;

use Error qw(:try);

use Class::WirelessApp;
use Class::Model;

# declare parent classes
#

# global variables
#
use constant TRUE => 1;
use constant FALSE => 0;

##################
# public methods #
##################

sub new
{
   my ($class, $interface) = @_;
   my $this = {};

   bless $this, $class;

   $this->{"interface"} = $interface;

   return $this;
}

sub init
{
   my ($I) = @_;
   my $model = Class::WirelessApp->getModel();
   my %Utils = $model->getUtils();

   # determine the location of a few necessary utilities...
   #
   my $iwconfig = $Utils{"iwconfig"};
   my $ifconfig = $Utils{"ifconfig"};
   my $dhcpcd = $Utils{"dhcpcd"};

   throw Error::MissingResourceException("Error: Unable to execute utility 'iwconfig'.  Unable to proceed!") unless(-x $iwconfig);
   throw Error::MissingResourceException("Error: Unable to execute utility 'ifconfig'.  Unable to proceed!") unless(-x $ifconfig);
   throw Error::MissingResourceException("Error: Unable to execute utility 'dhcpcd'.  Unable to proceed!") unless(-x $dhcpcd);
   
   $I->{"iwconfig"} = $iwconfig;
   $I->{"ifconfig"} = $ifconfig;
   $I->{"dhcpcd"} = $dhcpcd;

   # check if given interface is currently active
   #
   my $cmd = $I->{"ifconfig"};
   my $result = `$cmd` or throw Error::ExecutionException("Unable to verify interface activity");
   if($result =~ /$I->{"interface"}/gi)
   {
      # now that we know interface is active, try and find out
      # if there is an active connection
      # NOTE: the '-B' flag sent to the dhcpcd daemon requests a
      # response.
      #
      $cmd = $I->{"dhcpcd"} . " -B " . $I->{"interface"} . " &> /dev/null";
      $result = system($cmd) or throw Error::ExecutionException("Encountered an error while contacting dhcpcd daemon");
      if($result/256 == 1)
      {
         print "dhcpcd daemon is running, attempting to gather information about access point!\n";
         $cmd = $I->{"iwconfig"} . " " . $I->{"interface"} . " 2> /dev/null";
         `$cmd` =~ /essid\s?\:\s?\"?(\w+)\"?/gi or throw Error::ExecutionException("Unable to determine name of access point");
         $model->setConnectedAP($1);

         return;
      }
   }
   else
   {
      print "No currently active connection, identifying best network...\n";

      my $max = 0;
      my $profile;
      foreach my $ap (values %{ $model->getAPData() })
      {
         next unless my $apProfile = $model->getProfileBySid($ap->{"essid"});

         if( $max < eval($ap->get("quality")) )
         {
            $max = eval($ap->get("quality"));
            $profile = $apProfile;
         }
      }

      # found profiled access point with best quality signal,
      # attempt to connect...
      #
      $I->connect($profile) if $profile;

      # notify the model that there is now a connection!
      #
      $model->setConnectedAP($profile->get("essid"));
   } 
}

sub connect
{
   my ($I, $profile) = @_;

   #-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#
   # begin by setting up new connection using given parameters #
   #-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#

   # set connection mode...
   #
   print $I->{"iwconfig"} . " " . $I->{"interface"} . " mode " . $profile->get("mode") . "\n";
   if( system($I->{"iwconfig"} . " " . $I->{"interface"} . " mode " . $profile->get("mode")) < 0 )
   #if( system($I->{"iwconfig"}, $I->{"interface"}, "mode", $profile->get("mode")) < 0 )
   {
      throw Error::Simple("Failed setting interface mode");
   }

   # set essid...
   #
   print $I->{"iwconfig"} . " " . $I->{"interface"} . " essid \"" . $profile->get("essid") . "\"\n";
   if( system($I->{"iwconfig"} . " " . $I->{"interface"} . " essid \"" . $profile->get("essid") . "\"") < 0 )
   #if( system($I->{"iwconfig"}, $I->{"interface"}, "essid", "\"" . $profile->get("essid") . "\"") < 0 )
   {
      throw Error::Simple("Failed setting interface essid");
   }

   # set encryption key, if any
   #
   if($profile->get("encryption") eq "on")
   {
      print $I->{"iwconfig"} . " " . $I->{"interface"} . " key " . $profile->get("key") . "\n";
      if( system($I->{"iwconfig"}, $I->{"interface"}, "key", $profile->get("key")) < 0 )
      {
         throw Error::Simple("Failed setting encryption key");
      }
   }

   #-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#
   # start up wireless device and request new ip #
   #-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#

   print $I->{"ifconfig"} . " " . $I->{"interface"} . " up" . "\n";
   if( system($I->{"ifconfig"}, $I->{"interface"}, "up") < 0 )
   #if( system($I->{"ifconfig"}, $I->{"interface"}, "up") < 0 )
   {
      throw Error::Simple("Failed initializing interface");
   }

   print $I->{"dhcpcd"} . " " . $I->{"interface"} . "\n";
   if( system($I->{"dhcpcd"} . " " . $I->{"interface"}) < 0 )
   {
      throw Error::Simple("Failed aquiring new ip address");
   }

   print "done\n";
}

sub disconnect
{
   my ($I) = @_;

   print "Disconnecting from AccessPoint\n";

   # terminate existing connection (if one exists)
   # NOTE: sending '-k' flag to dhcpcd forces the daemon
   # to release current ip address.
   #
   print $I->{"dhcpcd"} . " -k " . $I->{"interface"} . "\n";
   if( system($I->{"dhcpcd"}, "-k", $I->{"interface"}) < 0 )
   {
      throw Error::Simple("Failed to terminate connection");
   }
}

1;#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#
