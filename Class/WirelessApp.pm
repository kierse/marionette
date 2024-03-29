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
#     $LastChangedBy$
#     $Date$
#     $Rev$
#     $URL$
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
my %Config;

sub new
{
   my ($class, $path) = @_;
   my $this = {};
   
   bless $this, $class;

   # set config variables...
   #
   %Config = (
      "configDir" => $ENV{"HOME"} . "/.wireless_app",
      "images" => 
      {
         "connected" => "$path/images/connected.gif",
         "available" => "$path/images/available.gif",
         "strength"  => 
         {
            "small" => 
            [
               "$path/images/smallStrength0.png",
               "$path/images/smallStrength1.png",
               "$path/images/smallStrength2.png",
               "$path/images/smallStrength3.png",
               "$path/images/smallStrength4.png",
               "$path/images/smallStrength5.png",
            ],
            "large" => 
            [
               "$path/images/largeStrength0.png",
               "$path/images/largeStrength1.png",
               "$path/images/largeStrength2.png",
               "$path/images/largeStrength3.png",
               "$path/images/largeStrength4.png",
               "$path/images/largeStrength5.png",
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
   $model = new Class::Model($Config{"configDir"});
   $model->init();

	# before creating the mainView, try and establish a connection
	#
	$I->createConnection();

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

   unless($connection && $connection->isa("Utility::Connection"))
   {
      Class::WirelessApp->createConnection();  
   }
   
   return $connection;
}

sub getConfig
{
   my ($class) = @_;

   return %Config;
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

   $connection = new Utility::Connection($model->getInterface());
   $connection->init();

   return $connection;
}

1;#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#
