#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#
#
#   Class:          MainView.pm
#
#   Author:         Kier Elliott
#
#   Date:           08/23/2004
#
#   Description:    
#
#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#

package Class::MainView;

use strict; use warnings;

use Gtk2 '-init';
use Gtk2::SimpleList;
use Gtk2::SimpleMenu;
use Error qw(:try);

use Class::View;
use Class::Model;
use Class::AccessPoint;
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
   my ($class, $model) = @_;

   # Initialize parent class
   #
   my $this = $class->SUPER::new($model);

   return $this;
}

sub init
{
   my ($I) = @_;

   # create new Gtk2 Window
   #
   my $window = new Gtk2::Window();

   # begin building main application view...
   #
   my $mainBox = new Gtk2::VBox(FALSE, 0);
   
   # generate menu widget
   #
   my $menu = $I->_constructMenu();
   $mainBox->pack_start($menu->{widget}, FALSE, FALSE, 0);
   
   # generate shell script box
   #
   my $shell = $I->_constructShellScriptBox();
   $mainBox->pack_start($shell, FALSE, FALSE, 10);

   # generate command box
   #
   my $command = $I->_constructCommandBox();
   $mainBox->pack_start($command, FALSE, FALSE, 0);

   # generate profile box
   #
   my $profile = $I->_constructProfileBox();
   $mainBox->pack_start($profile, TRUE, TRUE, 5);

   # add main box to window and add accelerator
   # group to window
   #
   $window->add($mainBox);
   $window->add_accel_group($menu->{accel_group});
   
   # set a few properties on the window object...
   #
   $window->set_position('center');
   #$window->set_resizable(FALSE);
   
   # save reference to window object
   #
   $I->{"window"} = $window;

   $window->show_all();
}

sub update
{
   my ($I) = @_;

   print "Updating MainView data...\n";
}

###################
# private methods #
###################

sub _constructMenu
{
   my ($I) = @_;

   # create a menu hierarchy in a tree format...
   #
   my $menu_tree = [
      _File => {
		   item_type => '<Branch>',
		   children => [
			   _Quit => {
   				callback => sub { Gtk2->main_quit; },
	   			callback_action => 3,
		   		accelerator => '<ctrl>Q',
			   },
   		],
	   },
   	_Profiles => {
	   	item_type => '<Branch>',
         children => [
            '_New Profile' => {
               callback_action => 0,
               accelerator => '<ctrl>N',
            },
            '_Edit Profile' => {
               callback_action => 1,
               accelerator => '<ctrl>E',
            },
            '_Delete Profile' => {
               callback_action => 2,
               accelerator => '<ctrl>D',
            },
            'Import from...' => {
               callback_action => 3,
            },
            'Export to...' => {
               callback_action => 4,
            },
         ],
      },
      _Help => {
         item_type => '<Branch>',
         children => [
            _About => {
               callback_action => 0,
            },
            _Help => {
               callback_action => 1,
               accelerator => '<ctrl>H',
            },
         ],
      },
   ];

   # Create a new Gtk2::SimpleMenu object using the menu tree
   #
   my $menu = new Gtk2::SimpleMenu(menu_tree => $menu_tree);

   return $menu;
}
sub _constructShellScriptBox
{
   my ($I) = @_;
   my $model = $I->{"model"};

   my $container = new Gtk2::VBox(TRUE, 5);

   # Create Frame to hold startup script file chooser
   # Create HBox to hold entry and button
   #
   my $scriptFrame = new Gtk2::Frame(" Startup Script ");
   my $scriptBox = new Gtk2::HBox(FALSE, 2);

   my $scriptEntry = new Gtk2::Entry();
   $scriptEntry->set_editable(FALSE);
   my $scriptButton = new_with_label Gtk2::Button("Browse");

   # add entry and button to box, then add box to frame...
   #
   $scriptBox->pack_start($scriptEntry, TRUE, TRUE, 0);
   $scriptBox->pack_start($scriptButton, FALSE, FALSE, 0);
   $scriptFrame->add($scriptBox);
   
   # Create Frame to hold profile dir file chooser
   # Create HBox to hold entry and button
   #
   my $profileFrame = new Gtk2::Frame(" Profile Directory ");
   my $profileBox = new Gtk2::HBox(FALSE, 2);
   
   my $profileEntry = new Gtk2::Entry();
   $profileEntry->set_editable(FALSE);
   my $profileButton = Gtk2::Button->new_with_label("Browse");

   # add entry and button to box, then add box to frame...
   #
   $profileBox->pack_start($profileEntry, TRUE, TRUE, 0);
   $profileBox->pack_start($profileButton, FALSE, FALSE, 0);
   $profileFrame->add($profileBox);

   # add script and profile frame to container
   #
   $container->pack_start($scriptFrame, TRUE, TRUE, 0);
   $container->pack_start($profileFrame, TRUE, TRUE, 0);

   # return completed script box to caller
   #
   return $container;
}

sub _constructCommandBox
{
   my ($I) = @_;

   # create command box
   #
   my $commandBox = new Gtk2::HBox(TRUE, 5);

   # create command buttons and add to box
   #
   my $new = new_with_label Gtk2::Button("New");
   my $edit = new_with_label Gtk2::Button("Edit");
   my $delete = new_with_label Gtk2::Button("Delete");
   my $scan = new_with_label Gtk2::Button("Scan");

   $commandBox->pack_start($new, TRUE, TRUE, 0);
   $commandBox->pack_start($edit, TRUE, TRUE, 0);
   $commandBox->pack_start($delete, TRUE, TRUE, 0);
   $commandBox->pack_start($scan, TRUE, TRUE, 0);

   return $commandBox;
}

sub _constructProfileBox
{
   my ($I) = @_;

   # create profile box
   #
   my $profileBox = new Gtk2::HBox(FALSE, 5);

   # create a new Gtk2::SimpleList object
   #
#   my $list = new Gtk2::SimpleList(
#      'Text Field'    => 'text',
#      'Markup Field'  => 'markup',
#      'Int Field'     => 'int',
#      'Double Field'  => 'double',
#      'Bool Field'    => 'bool',
#      'Scalar Field'  => 'scalar',
#      'Pixbuf Field'  => 'pixbuf',
#   );
   my $list = new Gtk2::SimpleList(
      '     ' => 'bool',
      'Profile' => 'text',
      'Access Point' => 'text',
   );

   push @{$list->{data}}, [1, 'HOME adf asdf asf :', 'Olympus'];   
   push @{$list->{data}}, [0, 'ERIN', 'JED'];   

   # create new up/down buttons to move profiles in list
   #
   my $buttonBox = new Gtk2::VBox(FALSE, 5);
   my $up = new_with_label Gtk2::Button("up");
   my $down = new_with_label Gtk2::Button("down");

   $buttonBox->pack_start($up, FALSE, FALSE, 0);
   $buttonBox->pack_end($down, FALSE, FALSE, 0);
   
   # add list and buttons to profileBox
   #
   $profileBox->pack_start($list, TRUE, TRUE, 0);
   $profileBox->pack_start($buttonBox, FALSE, FALSE, 0);


   return $profileBox;
}

sub _openFileSelector
{
   my ($I, $title, $type, $path) = @_;

   my $scriptChooser = new Gtk2::FileSelection("Startup Script");

   # finished, display chooser!
   #
   $scriptChooser->show();
}
