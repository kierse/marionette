#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#
#
#   Class:          Class::View::Scan
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
   $window->signal_connect("destroy", sub { $model->removeView($I); $window->destroy(); });

   # begin building scan view...
   #
   my $availableBox = new Gtk2::VBox(FALSE, 5);

   # construct list
   #
   my $list = $I->_constructList($model->getAPs());
   my $listVBox = new Gtk2::VBox(FALSE, 0);
   my $listContainer = new Gtk2::HBox(FALSE, 0);
   $listVBox->pack_start($list, TRUE, TRUE, 10);
   $listContainer->pack_start($listVBox, TRUE, TRUE, 10);

   # construct buttons...
   #
   my $buttons = $I->_constructButtons($list);
   my $buttonVBox = new Gtk2::VBox(FALSE, 0);
   my $buttonContainer = new Gtk2::HBox(FALSE, 0);
   $buttonVBox->pack_start($buttons, TRUE, TRUE, 10);
   $buttonContainer->pack_start($buttonVBox, TRUE, TRUE, 10);
   
   # add list and buttons to container and add to window...
   #
   $availableBox->pack_start($listContainer, TRUE, TRUE, 0);
   $availableBox->pack_start($buttonContainer, TRUE, TRUE, 0);
   $window->add($availableBox);

   # set a few properties on the window object...
   #
   $window->set_resizable(FALSE);
   $window->set_modal(TRUE);
   $window->set_position('center');

   $I->{"window"} = $window;
   $I->{"list"} = $list;

   $window->show_all();
}

sub update
{
   my ($I) = @_;
   my $model = Class::WirelessApp->getModel();
   my $list = $I->{"list"};

   print "Updating ScanView data...\n";
   
   # clear current list and repopulate with
   # new available access point list from model...
   #
   my %Aps = $model->getAPs();
   @{$list->{data}} = ();
   foreach my $ap (keys %Aps)
   {
      push @{$list->{data}}, ["", $Aps{$ap}, $ap];
   }
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

sub _constructButtons
{
   my ($I, $list) = @_;
   my $model = Class::WirelessApp->getModel();

   my $buttonBox = new Gtk2::HBox(FALSE, 0);

   my $scan = new_with_label Gtk2::Button("Scan");
   my $connect = new_with_label Gtk2::Button("Connect");
   my $cancel = new_with_label Gtk2::Button("Cancel");
   $buttonBox->pack_start($scan, TRUE, TRUE, 0);
   $buttonBox->pack_end($cancel, TRUE, TRUE, 0);
   $buttonBox->pack_end($connect, TRUE, TRUE, 0);

   # set action handlers...
   #
   $scan->signal_connect("clicked", sub { $I->{"controller"}->buttonHandler(@_); });
   $connect->signal_connect("clicked", sub { $I->{"controller"}->buttonHandler(@_, $list); });
   $cancel->signal_connect("clicked", sub { $model->removeView($I); $I->{"window"}->destroy(); });

   return $buttonBox;
}
