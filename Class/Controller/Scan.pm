#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#
#
#   Name:           Class::Controller::Scan
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
#     $Date: 2004-09-03 16:51:02 -0600 (Fri, 03 Sep 2004) $
#     $Rev: 10 $
#     $URL$
#
#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#

package Class::Controller::Scan;

use strict; use warnings;

use Class::WirelessApp;
use Class::Model;

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

sub buttonHandler
{
   my ($I, $button, @Args) = @_;
   my $model = Class::WirelessApp->getModel();

   if($button->get_label() eq "Connect")
   {
      my ($list, $scanView) = @Args;
      
      print "Class::View::Scan connect button caught!\n";

      # get currently selected network data...
      #
      my ($selected) = $list->get_selected_indices();
      my @Data = @{ $list->{data}[$selected] };

      # if selected network has a profile, attempt to connect,
      # otherwise, prompt user for necessary data to establish a
      # connection
      #
      my $profile;
      if($Data[0] ne "")
      {
         $profile = $model->getProfileByName($Data[0]);
      }
      else
      {
         print "haven't done this feature yet!\n";
         exit;
      }

      # create new connection to selected network
      #
      my $connection = Class::WirelessApp->getConnection();
      $connection->disconnect();
      $connection->connect($profile);

      # notify model of new connected ap...
      #
      $model->setConnectedAP($Data[1]);

      # close Scan view window...
      #
      $scanView->close();
   }
   elsif($button->get_label() eq "Scan")
   {
      print "Class::View::Scan scan button caught!\n";
      $model->scan();
   }
}

1;#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#
