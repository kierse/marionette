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
#     $LastChangedBy: kierse $
#     $Date: 2004-09-14 23:33:47 -0600 (Tue, 14 Sep 2004) $
#     $Rev: 23 $
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
   my %appConfigs = Class::WirelessApp->getConfig();

   my $eventBox = new Gtk2::EventBox();
   my $image = new_from_file Gtk2::Image($appConfigs{"images"}{"strength"}{"small"}[1]);
   $eventBox->add($image);

   # set event listeners on event box...
   #
   $eventBox->signal_connect("button-press-event", sub { $I->{"controller"}->eventHandler(@_); } );

   # store event box and image for later use...
   #
   $I->{"eventBox"} = $eventBox;
   $I->{"image"} = $image;

   return $eventBox;
}

sub update
{
   my ($I) = @_;
}

1;#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#
