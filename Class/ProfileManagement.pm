#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#
#
#   Class:          ProfileManagement.pm
#
#   Author:         Kier Elliott
#
#   Date:           09/05/2004
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

package Class::ProfileManagement;

use strict; use warnings;

use Class::WirelessApp;
use Class::View;
use Class::Model;
use Class::AccessPointProfile;

# declare parent classes
#
our @ISA = ("Class::View");

# global variables
#
use constant TRUE => 1;
use constant FALSE => 0;

##################
# public methods #
##################

sub new
{
   my ($class, $controller) = @_;

   # Initialize parent class
   #
   my $this = $class->SUPER::new($controller);

   return $this;
}

sub init
{
   my ($I) = @_;

   # create new Gtk2 Window
   #
   my $window = new Gtk2::Window();
   
   # begin building ProfileManagement view...
   #
   my $managementBox = new Gtk2::VBox(FALSE, 0);

   # construct tab views...
   #
   my $notebook = $I->_constructTabs();
   $window->add($notebook);

   # set a few properties on the window object...
   #
   $window->set_resizable(FALSE);
   $window->set_modal(TRUE);
   $window->set_position('center');
   
   $I->{"window"} = $window;

   $window->show_all();
}

###################
# private methods #
###################

sub _constructTabs
{
   my ($I) = @_;

   my $notebook = new Gtk2::Notebook();

   # set preferences regarding notebook creation
   #
   $notebook->set_tab_pos('top');

   # create import & export tabs and add to notebook...
   #
   my $import = $I->_createImportTab();
   my $export = $I->_createExportTab();
   $notebook->append_page($import, "Import Profiles");
   $notebook->append_page($export, "Export Profiles");

   $notebook->show();

   # construct notebook padding containers
   #
   my $vpad = new Gtk2::VBox(FALSE, 0);
   my $hpad = new Gtk2::HBox(FALSE, 0);
   $vpad->pack_start($notebook, TRUE, TRUE, 5);
   $hpad->pack_start($vpad, TRUE, TRUE, 5);

   return $hpad;
}

sub _createImportTab
{
   my ($I) = @_;

   # create main container...
   #
   my $importBox = new Gtk2::VBox(FALSE, 0);

   # create location widgets...
   #
   my $widgetBox = new Gtk2::HBox(FALSE, 0);
   my $locationEntry = new Gtk2::Entry();
   my $browseButton = new_with_label Gtk2::Button("Browse...");
   $widgetBox->pack_start($locationEntry, TRUE, TRUE, 0);
   $widgetBox->pack_start($browseButton, TRUE, TRUE, 0);

   my $locationHBox = new Gtk2::HBox(FALSE, 0);
   my $locationVBox = new Gtk2::VBox(FALSE, 0);
   $locationHBox->pack_start($widgetBox, TRUE, TRUE, 10);
   $locationVBox->pack_start($locationHBox, TRUE, TRUE, 10);

   my $locationFrame = new Gtk2::Frame();
   $locationFrame->set_label(" Choose location to import from... ");
   $locationFrame->set_label_align(0.0, 0.5);
   $locationFrame->add($locationVBox);
   
   my $locHBox = new Gtk2::HBox(FALSE, 0);
   my $locationBox = new Gtk2::VBox(FALSE, 0);
   $locHBox->pack_start($locationFrame, TRUE, TRUE, 10);
   $locationBox->pack_start($locHBox, TRUE, TRUE, 10);

   # create profile list widgets...
   #
   my $list = new Gtk2::SimpleList(
      '     ' => 'bool',
      'Profile' => 'text',
      'Access Point' => 'text',
   );
   
   # set any properties on new list
   #
   #$list->get_selection()->set_mode('multiple');
   $list->get_selection()->set_mode('single');
   $list->set_reorderable(TRUE);

   # get all profiles from the model and add to profile list
   #
   #foreach my $ap ( $I->{"model"}->getProfiles() )
   foreach my $ap ( Class::WirelessApp->getModel()->getProfiles() )
   {
      push @{$list->{data}}, [0, $ap->get("name"), $ap->get("essid")];
   }

   my $profileBox = new Gtk2::HBox(FALSE, 0);
   $profileBox->pack_start($list, TRUE, TRUE, 0);
   
   # add location box and profile box to main box and return
   #
   $importBox->pack_start($locationBox, FALSE, FALSE, 0);
   $importBox->pack_start($profileBox, FALSE, FALSE, 0);

   return $importBox;
}

sub _createExportTab
{
   my ($I) = @_;

   # create main container...
   #
   my $exportBox = new Gtk2::VBox(FALSE, 0);

   # create profile widgets...
   #
   my $profileBox = new Gtk2::HBox(FALSE, 0);

   # create location widgets...
   #
   my $widgetBox = new Gtk2::HBox(FALSE, 0);
   my $locationEntry = new Gtk2::Entry();
   my $browseButton = new_with_label Gtk2::Button("Browse...");
   $widgetBox->pack_start($locationEntry, TRUE, TRUE, 0);
   $widgetBox->pack_start($browseButton, TRUE, TRUE, 0);

   my $locationHBox = new Gtk2::HBox(FALSE, 0);
   my $locationVBox = new Gtk2::VBox(FALSE, 0);
   $locationHBox->pack_start($widgetBox, TRUE, TRUE, 10);
   $locationVBox->pack_start($locationHBox, TRUE, TRUE, 10);

   my $locationFrame = new Gtk2::Frame();
   $locationFrame->set_label(" Choose location to export to... ");
   $locationFrame->set_label_align(0.0, 0.5);
   $locationFrame->add($locationVBox);
   
   my $locHBox = new Gtk2::HBox(FALSE, 0);
   my $locationBox = new Gtk2::VBox(FALSE, 0);
   $locHBox->pack_start($locationFrame, TRUE, TRUE, 10);
   $locationBox->pack_start($locHBox, TRUE, TRUE, 10);
   
   # add profileBox and locationBox to exportBox and return
   #
   $exportBox->pack_start($profileBox, TRUE, TRUE, 0);
   $exportBox->pack_start($locationBox, FALSE, FALSE, 0);

   return $exportBox;
}
