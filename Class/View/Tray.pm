#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#
#
#   Name:          Class::View::Tray
#
#   Author:         Kier Elliott
#
#   Date:           09/17/2004
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

package Class::View::Tray;

use strict; use warnings;

# declare parent classes
#
our @ISA = ("Class::View::View");

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
   my $model = Class::WirelessApp->getModel();
   my %appConfigs = Class::WirelessApp->getConfig();

   my $eventBox = new Gtk2::EventBox();

   # update connection strength image to reflect current
   # data... Multiply decimal value by 4 to get a value on 
   # a four point scale (ie between 0-3, 3 being 75-100%)
   #
   my $num = 5;
   if($model->isConnected())
   {
      my $accessPoint = $model->getConnectedAP();
      my $quality = eval($accessPoint->get("quality"));

      $num = ($quality != 0 && $quality < 0.25)
         ? 1
         : ($quality * 4);
   }

   my $strength = new_from_file Gtk2::Image($appConfigs{"images"}{"strength"}{"small"}[$num]);
   
   $eventBox->add($strength);

   # set event listeners on event box...
   #
   $eventBox->signal_connect("button-press-event", sub { $I->{"controller"}->eventHandler(@_); } );

   # store event box and image for later use...
   #
   $I->{"eventBox"} = $eventBox;
   $I->{"strength"} = $strength;

   return $eventBox;
}

sub update
{
   my ($I) = @_;
   my $model = Class::WirelessApp->getModel();
   my %appConfigs = Class::WirelessApp->getConfig();

   print "Updating TrayView data...\n";
   
   # update connection strength image to reflect current
   # data... Multiply decimal value by 4 to get a value on 
   # a four point scale (ie between 0-3, 3 being 75-100%)
   #
   if( my $accessPoint = $model->getConnectedAP() )
   {
      my $quality = eval($accessPoint->get("quality"));
      my $num = ($quality != 0 && $quality < 0.25)
         ? 1
         : ($quality * 4);
      $I->{"strength"}->set_from_file($appConfigs{"images"}{"strength"}{"small"}[$num]);
   }
}

1;#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#
