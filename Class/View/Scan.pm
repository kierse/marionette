#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#
#
#   Class:          ScanView.pm
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
#     $Date: 2004-09-03 22:46:23 -0600 (Fri, 03 Sep 2004) $
#     $Rev: 11 $
#     $URL: svn+ssh://zeus/var/svn/wireless_app/trunk/Class/MainView.pm $
#
#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#

package Class::View::Scan;

use strict; use warnings;

use Class::WirelessApp;
use Class::Model;
use Class::View::View;

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

   # create new Gtk2 Window
   #
   my $window = new Gtk2::Window();

   # begin building scan view...
   #
   my $apBox = new Gtk2::HBox(FALSE, 0);

   # construct list
   #
   my $list = $I->_constructList($model->scan());

   my $vbox = new Gtk2::VBox(FALSE, 0);
   my $hbox = new Gtk2::HBox(FALSE, 0);
   $vbox->pack_start($list, TRUE, TRUE, 5);
   $hbox->pack_start($vbox, TRUE, TRUE, 5);

   $window->add($hbox);

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

sub _constructList
{
   my ($I, %Aps) = @_;

   my $list = new Gtk2::SimpleList(
      'Profile' => 'text',
      'Access Point' => 'text',
      'Address' => 'text',
   );

   # set any properties on new list
   #
   $list->get_selection()->set_mode('single');
   
   foreach my $ap (keys %Aps)
   {
      push @{$list->{data}}, ["", $Aps{$ap}, $ap];
   }

   return $list;
}
