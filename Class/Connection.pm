#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#
#
#   Class:          Class::Connection
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

package Class::Connection;

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
   my ($class) = @_;
   my $this = {};

   bless $this, $class;

   return $this;
}

sub init
{
   my ($I, $interface) = @_;

   # determine the location of a few necessary utilities...
   #
   my $iwconfig = `whereis -b iwconfig`;
   my $ifconfig = `whereis -b ifconfig`;
   my $dhcpcd = `whereis -b dhcpcd`;
   $iwconfig =~ s/(.+)?\:\s(.+)?\n/$2/gi;
   $ifconfig =~ s/(.+)?\:\s(.+)?\n/$2/gi;
   $dhcpcd =~ s/(.+)?\:\s(.+)?\n/$2/gi;

   throw Error::Simple("Error: Unable to find utility 'iwconfig'.  Unable to proceed!") unless($iwconfig && $iwconfig ne "");
   throw Error::Simple("Error: Unable to find utility 'ifconfig'.  Unable to proceed!") unless($ifconfig && $ifconfig ne "");
   throw Error::Simple("Error: Unable to find utility 'dhcpcd'.  Unable to proceed!") unless($ifconfig && $ifconfig ne "");
   
   $I->{"iwconfig"} = $iwconfig;
   $I->{"ifconfig"} = $ifconfig;
   $I->{"dhcpcd"} = $dhcpcd;
   $I->{"interface"} = $interface;
}

sub connect
{
   my ($I, %Params) = @_;

   #-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#
   # begin by setting up new connection using given parameters #
   #-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#

   # set connection mode...
   #
   if( system($I->{"iwconfig"}, $I->{"interface"}, "mode", $Params{"mode"}) < 0 )
   {
      throw Error::Simple("Failed setting interface mode");
   }

   # set essid...
   #
   if( system($I->{"iwconfig"} . " " . $I->{"interface"} . " essid " . $Params{"essid"}) < 0 )
   {
      throw Error::Simple("Failed setting interface essid");
   }

   # set encryption key, if any
   #
   if($Params{"encryption"} eq "on")
   {
      if( system($I->{"iwconfig"} . " " . $I->{"interface"} . " key " . $Params{"key"}) < 0 )
      {
         throw Error::Simple("Failed setting encryption key");
      }
   }

   #-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#
   # start up wireless device and request new ip #
   #-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#

   if( system($I->{"ifconfig"} . " " . $I->{"interface"} . " up") < 0 )
   {
      throw Error::Simple("Failed initializing interface");
   }

   if( system($I->{"dhcpcd"} . " " . $I->{"interface"}) < 0 )
   {
      throw Error::Simple("Failed aquiring new ip address");
   }
}

sub disconnect
{
   my ($I) = @_;

   # terminate existing connection (if one exists)
   #
   if( system($I->{"dhcpcd"} . " -k " . $I->{"interface"}) < 0 )
   {
      throw Error::Simple("Failed to terminate connection");
   }
}

1;#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#
