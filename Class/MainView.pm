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
#
#   Subversion Info:
#     $LastChangedBy$
#     $Date$
#     $Rev$
#     $URL$
#
#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#

package Class::MainView;

use strict; use warnings;

use Gtk2::SimpleList;
use Gtk2::SimpleMenu;
use Error qw(:try);

use Class::WirelessApp;
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

   # begin building main application view...
   #
   my $mainBox = new Gtk2::VBox(FALSE, 0);
   
   # generate all widgets
   #
   my ($menu, $shell, $command, $profile) = $I->_constructView();

   # add all widgets to main box...
   #
   $mainBox->pack_start($menu->{widget}, FALSE, FALSE, 0);
   $mainBox->pack_start($shell, FALSE, FALSE, 10);
   $mainBox->pack_start($command, FALSE, FALSE, 0);
   $mainBox->pack_start($profile, TRUE, TRUE, 5);

   # ...and add main box to window
   #
   $window->add($mainBox);
   $window->add_accel_group($menu->{accel_group});
   
   # set a few properties on the window object...
   #
   $window->set_position('center');
   
   # save reference to window object
   #
   $I->{"window"} = $window;

   $window->show_all();
}

sub newProfile
{

}

sub editProfile
{

}

sub deleteProfile
{

}

sub updateAccessPoints
{

}

sub update
{
   my ($I) = @_;

   print "Updating MainView data...\n";
}

sub confirmAction
{
   my ($I, $title, $question) = @_;

   my $dialog = new_with_buttons Gtk2::Dialog(
      $title, 
      $I->{"window"},
      'destroy-with-parent',
      'gtk-ok' => 'ok', 
      'gtk-cancel' => 'cancel',
   );
   
   my $label = new Gtk2::Label($question);
   my $vbox = new Gtk2::VBox(TRUE, 0);
   my $hbox = new Gtk2::HBox(TRUE, 0);
   $vbox->pack_start($label, TRUE, TRUE, 20);
   $hbox->pack_start($vbox, TRUE, TRUE, 20);
   
   $hbox->show();
   $vbox->show();
   $label->show();
   
   $dialog->vbox->add($hbox);

   # Ensure that the dialog box is destroyed when the user responds.
   #
   $dialog->signal_connect (response => sub {});
   
   if('ok' eq $dialog->run())
   {
      $dialog->destroy();
      return 1;
   }
   else
   {
      $dialog->destroy();
      return 0;
   }
}

sub fileSelection
{
   my ($I, $title, %Params) = @_;

#   my $selector = new Gtk2::FileSelection($title);
#   
#   # if user provided a desired starting path, set it
#   #
#   $selector->set_filename($Params{"path"}) if exists $Params{"path"};
#
#   # if user provided a match pattern for directory items, set it
#   #
#   $selector->complete($Params{"pattern"}) if exists $Params{"pattern"};
#
#   # check if users wants file operation buttons displayed...
#   #
#   if(exists $Params{"fileops"})
#   {
#      $Params{"fileops"}
#         ? $selector->show_fileop_buttons()
#         : $selector->hide_fileop_buttons();
#   }
#
#   # set signal handlers...
#   #
#   
#   $selector->show();

   my $chooser = new Gtk2::FileChooserDialog(
      "Test File Chooser",
      $I->{"window"},
      'open',
      'gtk-ok' => 'ok', 
      'gtk-cancel' => 'cancel',
   );

   # Ensure that the dialog box is destroyed when the user responds.
   #
   $chooser->signal_connect (response => sub {});
   
   if('ok' eq $chooser->run())
   {
      $chooser->destroy();
      print $chooser->get_filename();

   }
   else
   {
      $chooser->destroy();
      return 0;
   }
}

##################
# setter methods #
##################

sub setStartupScript
{
   my ($I, $path) = @_;

   try
   {
      # if given script path does not exist, throw an error
      #
      throw Error::Simple("Given startup script '$path' does not exist!") unless(-e $path);
   
      $I->{"startupScript"}->set_text($path);
   }
   catch Error with
   {

   }
}

sub setProfileDir
{
   my ($I, $path) = @_;

   try
   {
      # if given profile dir does not exist, throw an error
      #
      throw Error::Simple("Given profile directory '$path' does not exist!") unless(-d $path);
   
      $I->{"profileDir"}->set_text($path);
   }
   catch Error with
   {

   }
}

##################
# setter methods #
##################

sub getStartupScript
{
   my ($I) = @_;

   return $I->{"startupScript"}->get_text();
}

sub getProfileDir
{
   my ($I) = @_;

   return $I->{"profileDir"}->get_text();
}

###################
# private methods #
###################

sub _constructView
{
   my ($I) = @_;
   my $model = Class::WirelessApp->getModel();

   # declare all variables here as some will be need to be used
   # when signal handlers are created
   #
   my ($menu_tree, $menu);
   my ($startupFrame, $startupBox, $startupEntry, $startupButton);
   my ($profiledirFrame, $profiledirBox, $profiledirEntry, $profiledirButton);
   my ($new, $edit, $delete, $scan);
   my ($list, $buttonBox, $up, $down);

   #-#-#-#-#-#-#-#-#-#-#
   # Main Menu         #
   #-#-#-#-#-#-#-#-#-#-#

   # create a menu hierarchy in a tree format...
   #
   $menu_tree = [
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
   $menu = new Gtk2::SimpleMenu(menu_tree => $menu_tree);

   #-#-#-#-#-#-#-#-#-#-#
   # Script Box        #
   #-#-#-#-#-#-#-#-#-#-#

   my $configBox = new Gtk2::VBox(TRUE, 5);
   
   # Create Frame to hold startup script file chooser
   # Create HBox to hold entry and button
   #
   $startupFrame = new Gtk2::Frame(" Startup Script ");
   $startupBox = new Gtk2::HBox(FALSE, 2);

   $startupEntry = new Gtk2::Entry();
   $startupEntry->set_editable(FALSE);
   $startupButton = new_with_label Gtk2::Button("Browse");

   # add entry and button to box, then add box to frame...
   #
   $startupBox->pack_start($startupEntry, TRUE, TRUE, 0);
   $startupBox->pack_start($startupButton, FALSE, FALSE, 0);
   $startupFrame->add($startupBox);
   
   # Create Frame to hold profile dir file chooser
   # Create HBox to hold entry and button
   #
   $profiledirFrame = new Gtk2::Frame(" Profile Directory ");
   $profiledirBox = new Gtk2::HBox(FALSE, 2);
   
   $profiledirEntry = new Gtk2::Entry();
   $profiledirEntry->set_editable(FALSE);
   $profiledirButton = Gtk2::Button->new_with_label("Browse");

   # add entry and button to box, then add box to frame...
   #
   $profiledirBox->pack_start($profiledirEntry, TRUE, TRUE, 0);
   $profiledirBox->pack_start($profiledirButton, FALSE, FALSE, 0);
   $profiledirFrame->add($profiledirBox);

   # add script and profile frame to container
   #
   $configBox->pack_start($startupFrame, TRUE, TRUE, 0);
   $configBox->pack_start($profiledirFrame, TRUE, TRUE, 0);

   # set action listeners...
   #
   $startupButton->signal_connect("clicked", sub { $I->{"controller"}->buttonHandler(shift @_, "StartupScript", $startupEntry) });
   $profiledirButton->signal_connect("clicked", sub { $I->{"controller"}->buttonHandler(shift @_, "ProfileDir", $profiledirEntry) });

   # set startup script and profile directory fields...
   #
   $startupEntry->set_text( $model->getStartupScript() );
   $profiledirEntry->set_text( $model->getProfileDir() );

   #-#-#-#-#-#-#-#-#-#-#
   # Command Box       #
   #-#-#-#-#-#-#-#-#-#-#

   my $commandBox = new Gtk2::HBox(TRUE, 5);
   
   # create command buttons
   #
   $new = new_with_label Gtk2::Button("New Profile");
   $edit = new_with_label Gtk2::Button("Edit Profile");
   $delete = new_with_label Gtk2::Button("Delete Profile(s)");
   $scan = new_with_label Gtk2::Button("Scan");

   # set action listeners...
   #
   $new->signal_connect("clicked", sub { $I->{"controller"}->buttonHandler(shift @_); });
   $edit->signal_connect("clicked", sub { $I->{"controller"}->buttonHandler(shift @_, $list); });
   $delete->signal_connect("clicked", sub { $I->{"controller"}->buttonHandler(shift @_, $list); });
   $scan->signal_connect("clicked", sub { $I->{"controller"}->buttonHandler(shift @_, $list); });

   $commandBox->pack_start($new, TRUE, TRUE, 0);
   $commandBox->pack_start($edit, TRUE, TRUE, 0);
   $commandBox->pack_start($delete, TRUE, TRUE, 0);
   $commandBox->pack_start($scan, TRUE, TRUE, 0);

   #-#-#-#-#-#-#-#-#-#-#
   # Profile Box       #
   #-#-#-#-#-#-#-#-#-#-#

   my $profileBox = new Gtk2::HBox(FALSE, 5);

   # create a new Gtk2::SimpleList object
   #
   $list = new Gtk2::SimpleList(
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

   # create new up/down buttons to move profiles in list
   #
   $buttonBox = new Gtk2::VBox(FALSE, 5);
   $up = new_with_label Gtk2::Button("up");
   $down = new_with_label Gtk2::Button("down");

   $buttonBox->pack_start($up, FALSE, FALSE, 0);
   $buttonBox->pack_end($down, FALSE, FALSE, 0);
   
   # add list and buttons to profileBox
   #
   $profileBox->pack_start($list, TRUE, TRUE, 0);
   $profileBox->pack_start($buttonBox, FALSE, FALSE, 0);
   
   # set action listeners...
   #
   $up->signal_connect("clicked", sub { $I->{"controller"}->buttonHandler(shift @_, $list); });
   $down->signal_connect("clicked", sub { $I->{"controller"}->buttonHandler(shift @_, $list); });

   # Return newly created widgets to caller
   #
   return ($menu, $configBox, $commandBox, $profileBox);
}

sub _openFileSelector
{
   my ($I, $title, $type, $path) = @_;

   my $scriptChooser = new Gtk2::FileSelection($title);
   $scriptChooser->show_fileop_buttons();

   # if a path is given, set filechooser to given path
   #
   $scriptChooser->set_filename($path) if $path;

   # finished, display chooser!
   #
   $scriptChooser->show();

   return $scriptChooser->get_filename();
}

####################
# callback methods #
####################

sub _buttonListener
{
   my ($button, @Args) = @_;
   my $I = pop @Args;
   my $controller = $I->{"controller"};

print ref $I;
exit;

   # call MainViewController button handler
   #
   $controller->buttonHandler(@Args);
}

1;#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#
