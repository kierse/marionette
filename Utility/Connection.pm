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

   my %Utils = Class::WirelessApp->getModel()->getUtils();

   # determine the location of a few necessary utilities...
   #
   my $iwconfig = $Utils{"iwconfig"};
   my $ifconfig = $Utils{"ifconfig"};
   my $dhcpcd = $Utils{"dhcpcd"};

   throw Error::Simple("Error: Unable to execute utility 'iwconfig'.  Unable to proceed!") unless(-x $iwconfig);
   throw Error::Simple("Error: Unable to execute utility 'ifconfig'.  Unable to proceed!") unless(-x $ifconfig);
   throw Error::Simple("Error: Unable to execute utility 'dhcpcd'.  Unable to proceed!") unless(-x $dhcpcd);
   
   $I->{"iwconfig"} = $iwconfig;
   $I->{"ifconfig"} = $ifconfig;
   $I->{"dhcpcd"} = $dhcpcd;
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

   # terminate existing connection (if one exists)
   #
   print $I->{"dhcpcd"} . " -k " . $I->{"interface"} . "\n";
   if( system($I->{"dhcpcd"}, "-k", $I->{"interface"}) < 0 )
   {
      throw Error::Simple("Failed to terminate connection");
   }
}

1;#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#
