#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#
#
#   Class:          Class::Controller::Main
#
#   Author:         Kier Elliott
#
#   Date:           09/03/2004
#
#   Description:    
#
#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#
#
#   Subversion Info:
#     $LastChangedBy: kierse $
#     $Date: 2004-09-03 16:51:02 -0600 (Fri, 03 Sep 2004) $
#     $Rev: 10 $
#     $URL: svn+ssh://zeus/var/svn/wireless_app/trunk/Class/MainView.pm $
#
#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#

package Class::Controller::Main;

use strict; use warnings;

use Class::Model;
use Class::View::Main;

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

sub menuHandler
{
   my ($I, $itemName, $itemNum, $item, @Args) = @_;

   if($itemName eq "new")
   {
      print "menu option 'new' caught!\n";
   }
   elsif($itemName eq "edit")
   {
      print "menu option 'edit' caught!\n";
   }
   elsif($itemName eq "delete")
   {
      my ($list) = @Args;
      
      print "menu option 'delete' caught!\n";
      _deleteProfile($list);
   }
   elsif($itemName eq "import")
   {
      print "menu option 'import' caught!\n";
      my $management = Class::WirelessApp->createProfileManagementView(0);
   }
   elsif($itemName eq "export")
   {
      print "menu option 'export' caught!\n";
      my $management = Class::WirelessApp->createProfileManagementView(1);
   }
   elsif($itemName eq "about")
   {
      print "menu option 'about' caught!\n";
   }
   elsif($itemName eq "help")
   {
      print "menu option 'help' caught!\n";
   }
}

sub buttonHandler
{
   my ($I, $button, @Args) = @_;
   my $mainView = Class::WirelessApp->getMainView();
   my $model = Class::WirelessApp->getModel();

   print "button click caught!\n";

   if($button->get_label() eq "Browse")
   {
      my ($var, $textField) = @_;
      
      #print "browse button click caught!\n";
      #$Args[0]->set_text("Change text!");

      my %Params;
      if($var eq "StartupScript")
      {
         print "update startupScript path caught!\n";
         %Params = (
            path => $model->getStartupScript(),
            fileops => 1,
         );
      }
      else
      {
         print "update profileDir path caught!\n";
         %Params = (
            path => $model->getProfileDir(),
            fileops => 1,
         );
      }

      $mainView->fileSelection(
         "File Selector", 
         %Params,
      );
   }
   elsif($button->get_label() eq "New Profile")
   {
      print "new button click caught!\n";
   }
   elsif($button->get_label() eq "Edit Profile")
   {
      print "edit button click caught!\n";
   }
   elsif($button->get_label() eq "Delete Profile")
   {
      my ($list) = @Args;

      print "delete button click caught!\n";
      _deleteProfile($list);
   }
   elsif($button->get_label() eq "Scan")
   {
      print "scan button click caught!\n";

      Class::WirelessApp->createScanView();
   }
   elsif($button->get_label() eq "up")
   {
      my ($list) = @Args;

      
   }
   elsif($button->get_label() eq "down")
   {
      print "down button click caught!\n";
   }
}

###################
# private methods #
###################

sub _newProfile
{

}

sub _editProfile
{

}

sub _deleteProfile
{
   my ($list) = @_;
   my $model = Class::WirelessApp->getModel();
   my $mainView = Class::WirelessApp->getMainView();

   # get list of selected profiles...
   #
   my @Rows = $list->get_selected_indices();

   # exit handler if user didn't have any profiles 
   # selected...
   #
   return if(scalar @Rows == 0);

   # get data for selected profiles and remove from 
   # model and profile list
   # Note: have to reverse selected rows list so that profiles
   #       are removed in reverse order otherwise row numbers
   #       change as profiles are removed from head :)
   #
   @Rows = reverse @Rows;
   for(my $i = 0; $i < scalar @Rows; $i++)
   {
      my @Ap = @{ $list->{data}[$Rows[$i]] }; # get profile data...

      # prompt user to confirm delete action
      #
      next unless($mainView->confirmAction("Confirm Delete", "Are you sure you want to delete the '" . $Ap[1] . "' profile?"));
   
      $model->destroyProfile($Ap[1]);   # $ap[1] contains profile name
         
      # remove profile from list
      #
      splice @{$list->{data}}, $Rows[$i], 1;
   }

   # give list focus
   #
   $list->grab_focus();
}

1;#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#
