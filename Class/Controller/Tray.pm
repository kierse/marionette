#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#
#
#   Name:           Class::Controller::Tray
#
#   Author:         Kier Elliott
#
#   Date:           09/18/2004
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

package Class::Controller::Tray;

use strict; use warnings;

use Class::WirelessApp;

##################
# public methods #
##################

sub new
{
   my ($class) = @_;
   my $this = {};

   bless $this, $class;   

   # create new flag to indicate display status of main view
   #
   $this->{"visible"} = 1;
   
   return $this;
}

sub eventHandler
{
   my ($I, $data, $event, @Args) = @_;
   my $mainView = Class::WirelessApp->getMainView();
   
   if($I->{"visible"})
   {
      $mainView->hide();
      $I->{"visible"} = 0;
   }
   else
   {
      $mainView->show();
      $I->{"visible"} = 1;
   }
}

1;#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#
