#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#
#
#   Class:          MainViewController.pm
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

package Class::MainViewController;

use strict; use warnings;

use Class::Model;
use Class::MainView;

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
   my ($I, $item, @Args) = @_;
}

sub buttonHandler
{
   my ($I, $button, @Args) = @_;
   my $mainView = Class::WirelessApp->getMainView();
   my $model = Class::WirelessApp->getModel();

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

      my $management = Class::WirelessApp->createProfileManagementView();
   }
   elsif($button->get_label() eq "Delete Profile(s)")
   {
      my ($list) = @Args;

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
   elsif($button->get_label() eq "Scan")
   {
      print "scan button click caught!\n";
      $model->scan();
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

1;#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#
