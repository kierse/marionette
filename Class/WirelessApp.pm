#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#
#
#   Class:          Class::WirelessApp
#
#   Author:         Kier Elliott
#
#   Date:           08/31/2004
#
#   Description:    
#
#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#
#
#   Subversion Info:
#     $LastChangedBy: kierse $
#     $Date: 2004-08-30 00:05:18 -0600 (Mon, 30 Aug 2004) $
#     $Rev: 5 $
#     $URL: svn+ssh://zeus/var/svn/wireless_app/trunk/Class/MainView.pm $
#
#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#

package Class::WirelessApp;

use strict; use warnings;

use Gtk2 '-init';
use Gtk2::TrayIcon;
use Error qw(:try);

use Class::Model;
use Class::View::Main;
use Class::View::ProfileManagement;
use Class::View::Scan;
use Class::View::Tray;
use Class::Controller::Main;
use Class::Controller::Scan;
use Class::Controller::Tray;
use Utility::Connection;

# Global variables
#
my $model;
my $mainView;
my $connection;
my %config;

sub new
{
   my ($class) = @_;
   my $this = {};
   
   bless $this, $class;

   # set config variables...
   #
   %config = (
      "configDir" => $ENV{"HOME"} . "/.wireless_app",
      "images" => 
      {
         "connected" => "images/connected.gif",
         "available" => "images/available.gif",
         "strength"  => 
         {
            "small" => 
            [
               "images/smallStrength0.png",
               "images/smallStrength1.png",
               "images/smallStrength2.png",
               "images/smallStrength3.png",
               "images/smallStrength4.png",
            ],
            "large" => 
            [
               "images/largeStrength0.png",
               "images/largeStrength1.png",
               "images/largeStrength2.png",
               "images/largeStrength3.png",
               "images/largeStrength4.png",
            ],
         }
      }
   );

   return $this;
}

sub run
{
   my ($I) = @_;

   # create and initialize necessary objects
   #
   $model = new Class::Model("wlan0");
   $model->init();

   my $mainViewController = new Class::Controller::Main();
   $mainView = new Class::View::Main($mainViewController);
   $mainView->init();

   my $trayViewController = new Class::Controller::Tray();
   my $trayView = new Class::View::Tray($trayViewController);
   my $tray = new Gtk2::TrayIcon("tray");
   $tray->add($trayView->init());
   $tray->show_all();

   # register new views with model...
   #
   $model->registerView($trayView);
   $model->registerView($mainView);

   # create any required timeouts...
   # NOTE: read about timeouts and idle calls in missing functions section
   # of Gtk2 Perl documentation at: http://gtk2-perl.sourceforge.net/doc/pod/Gtk2/api.html
   #
   Glib::Timeout->add(30000, sub { $model->scanConnectedAP() });

   # start up gtk and wait for user input
   #
   Gtk2->main();

   $model->clean();
}


##################
# class methods  #
##################

sub getModel
{
   my ($class) = @_;

   return $model;
}

sub getMainView
{
   my ($class) = @_;

   return $mainView;
}

sub getConnection
{
   my ($class) = @_;

   unless($connection && $connection->isa("Class::Connection"))
   {
      Class::WirelessApp->createConnection();  
   }

   return $connection;
}

sub getConfig
{
   my ($class) = @_;

   return %config;
}

sub createProfileManagementView
{
   my ($class, $page) = @_;

   my $profileManagementController = "";
   my $profileManagementView = new Class::View::ProfileManagement($profileManagementController);
   $profileManagementView->init();
   $profileManagementView->setPage($page);

   return $profileManagementView;
}

sub createScanView
{
   my ($class) = @_;

   my $scanViewController = new Class::Controller::Scan();
   my $scanView = new Class::View::Scan($scanViewController);
   $scanView->init();

   # register the new view with the model...
   #
   $model->registerView($scanView);

   return $scanView;
}

sub createConnection
{
   my ($class) = @_;

   $connection = new Utility::Connection("wlan0");
   $connection->init();

   return $connection;
}

1;#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#
