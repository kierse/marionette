#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#
#
#   Class:          WirelessApp.pm
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

use Class::Model;
use Class::MainView;
use Class::MainViewController;
use Class::ProfileManagement;

# Global variables
#
my $model;
my $mainView;

sub new
{
   my ($class) = @_;
   my $this = {};
   
   bless $this, $class;

   return $this;
}

sub run
{
   my ($I) = @_;

   # create and initialize necessary objects
   #
   $model = new Class::Model("wlan0");
   $model->init();

   my $mainViewController = new Class::MainViewController();
   $mainView = new Class::MainView($mainViewController);
   $mainView->init();

   my $tray = new Gtk2::TrayIcon("test");
   my $pix = new_from_file Gtk2::Image('/home/kierse/working/wireless_app/trunk/images/toolbar.gif');
   my $label = new Gtk2::Label(":)");
   #$tray->add($label);
   $tray->add($pix);
   $tray->show_all();

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

sub createProfileManagementView
{
   my ($class) = @_;

   my $profileManagementController = "";
   my $profileManagementView = new Class::ProfileManagement($profileManagementController);
   $profileManagementView->init();

   return $profileManagementView;
}

1;#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#