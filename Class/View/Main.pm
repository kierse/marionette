#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#
#
#   Class:          Class::View::Main
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

package Class::View::Main;

use strict; use warnings;

use Gtk2::SimpleList;
use Gtk2::SimpleMenu;
use Error qw(:try);

use Class::WirelessApp;
use Class::Model;
use Class::AccessPoint;
use Class::AccessPointProfile;
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

   # create new Gtk2 Window
   #
   my $window = new Gtk2::Window();
   $window->signal_connect("destroy" => sub { Gtk2->main_quit; } );

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

sub update
{
   my ($I) = @_;
   my $model = Class::WirelessApp->getModel();
   my $list = $I->{"list"};

   print "Updating MainView data...\n";

   # clear current list and repopulate with
   # new profile data from model...
   #
   @{$list->{data}} = ();
   push @{$list->{data}}, $I->_populateList($model);
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

   # declare all interactive widgets here (buttons, text fields, etc)
   # as some will be need to be used when signal handlers are created
   #
   my ($startupEntry, $startupButton);
   my ($profileEntry, $profileButton);
   my ($new, $edit, $delete, $scan);
   my ($list, $up, $down);

   #-#-#-#-#-#-#-#-#-#-#
   # Main Menu         #
   #-#-#-#-#-#-#-#-#-#-#

   # create a menu hierarchy in a tree format...
   #
   my $menu_tree = [
      _File => {
		   item_type => '<Branch>',
		   children => [
			   _Quit => {
   				callback => sub { Gtk2->main_quit; },
	   			callback_action => 0,
		   		accelerator => '<ctrl>Q',
               item_type => '<StockItem>',
               extra_data => 'gtk-quit',
			   },
   		],
	   },
   	_Profiles => {
	   	item_type => '<Branch>',
         children => [
            '_New Profile' => {
               callback_action => 1,
               callback_data => "new",
               accelerator => '<ctrl>N',
               item_type => '<StockItem>',
               extra_data => 'gtk-new',
            },
            '_Edit Profile' => {
               callback_action => 2,
               callback_data => "edit",
               accelerator => '<ctrl>E',
            },
            '_Delete Profile' => {
               callback => sub { $I->{"controller"}->menuHandler(@_, $list); },
               callback_action => 3,
               callback_data => "delete",
               accelerator => '<ctrl>D',
               item_type => '<StockItem>',
               extra_data => 'gtk-delete',
            },
            'sep1' => {
               item_type => '<Separator>',
            },
            'Import from...' => {
               callback_action => 4,
               callback_data => "import",
            },
            'Export to...' => {
               callback_action => 5,
               callback_data => "export",
            },
         ],
      },
      _Help => {
         item_type => '<LastBranch>',
         children => [
            _About => {
               callback_action => 6,
               callback_data => "about",
            },
            _Help => {
               callback_action => 7,
               callback_data => "help",
               accelerator => '<ctrl>H',
            },
         ],
      },
   ];

   # Create a new Gtk2::SimpleMenu object using the menu tree
   #
   my $menu = new Gtk2::SimpleMenu(
      menu_tree => $menu_tree,
      default_callback => sub { $I->{"controller"}->menuHandler(@_); },
   );
         
   #-#-#-#-#-#-#-#-#-#-#
   # Script Box        #
   #-#-#-#-#-#-#-#-#-#-#

   my $configBox = new Gtk2::VBox(TRUE, 5);
   
   # layout startup script widgets...
   #
   my $scriptWidgets = new Gtk2::HBox(FALSE, 5);
   $startupEntry = new Gtk2::Entry();
   $startupEntry->set_editable(FALSE);
   $startupButton = new_with_label Gtk2::Button("Browse");
   $scriptWidgets->pack_start($startupEntry, TRUE, TRUE, 0);
   $scriptWidgets->pack_start($startupButton, FALSE, FALSE, 0);
   
   my $startupHBox = new Gtk2::HBox(FALSE, 0);
   my $startupVBox = new Gtk2::VBox(FALSE, 0);
   $startupHBox->pack_start($scriptWidgets, TRUE, TRUE, 10);
   $startupVBox->pack_start($startupHBox, TRUE, TRUE, 10);

   my $startupFrame = new Gtk2::Frame(" Startup Script ");
   $startupFrame->add($startupVBox);
   
   # layout profile dir widgets...
   #
   my $profiledirWidgets = new Gtk2::HBox(FALSE, 5);
   $profileEntry = new Gtk2::Entry();
   $profileEntry->set_editable(FALSE);
   $profileButton = Gtk2::Button->new_with_label("Browse");
   $profiledirWidgets->pack_start($profileEntry, TRUE, TRUE, 0);
   $profiledirWidgets->pack_start($profileButton, FALSE, FALSE, 0);

   my $profiledirHBox = new Gtk2::HBox(FALSE, 0);
   my $profiledirVBox = new Gtk2::VBox(FALSE, 0);
   $profiledirHBox->pack_start($profiledirWidgets, TRUE, TRUE, 10);
   $profiledirVBox->pack_start($profiledirHBox, TRUE, TRUE, 10);
   
   my $profileFrame = new Gtk2::Frame(" Profile Directory ");
   $profileFrame->add($profiledirVBox);
   
   # add frames to boxes to provide padding...
   #
   my $selectVBox = new Gtk2::VBox(FALSE, 0);
   my $selectHBox = new Gtk2::HBox(FALSE, 0);
   $selectVBox->pack_start($startupFrame, TRUE, TRUE, 5);
   $selectVBox->pack_start($profileFrame, TRUE, TRUE, 0);
   $selectHBox->pack_start($selectVBox, TRUE, TRUE, 10);
   
   # add script and profile frame to container
   #
   $configBox->pack_start($selectHBox, TRUE, TRUE, 0);

   # set action listeners...
   #
   $startupButton->signal_connect("clicked", sub { $I->{"controller"}->buttonHandler(shift @_, "StartupScript", $startupEntry) });
   $profileButton->signal_connect("clicked", sub { $I->{"controller"}->buttonHandler(shift @_, "ProfileDir", $profileEntry) });

   # set startup script and profile directory fields...
   #
   #$startupEntry->set_text( $model->getStartupScript() );
   $profileEntry->set_text( $model->getProfileDir() );

   #-#-#-#-#-#-#-#-#-#-#
   # Command Box       #
   #-#-#-#-#-#-#-#-#-#-#

   my $commandBox = new Gtk2::HBox(TRUE, 5);
   
   # create command buttons
   #
   my $commandWidgets = new Gtk2::HButtonBox();
   $new = new_with_label Gtk2::Button("New Profile");
   $edit = new_with_label Gtk2::Button("Edit Profile");
   $delete = new_with_label Gtk2::Button("Delete Profile");
   $scan = new_with_label Gtk2::Button("Scan");
   $commandWidgets->add($new);
   $commandWidgets->add($edit);
   $commandWidgets->add($delete);
   $commandWidgets->add($scan);
   $commandWidgets->set_spacing_default(5);
   $commandWidgets->set_layout('spread');

   my $commandHBox = new Gtk2::HBox(FALSE, 0);
   my $commandVBox = new Gtk2::VBox(FALSE, 0);
   $commandHBox->pack_start($commandWidgets, TRUE, TRUE, 10);
   $commandVBox->pack_start($commandHBox, TRUE, TRUE, 0);

   # set action listeners...
   #
   $new->signal_connect("clicked", sub { $I->{"controller"}->buttonHandler(shift @_); });
   $edit->signal_connect("clicked", sub { $I->{"controller"}->buttonHandler(shift @_, $list); });
   $delete->signal_connect("clicked", sub { $I->{"controller"}->buttonHandler(shift @_, $list); });
   $scan->signal_connect("clicked", sub { $I->{"controller"}->buttonHandler(shift @_, $list); });

   $commandBox->pack_start($commandVBox, TRUE, TRUE, 0);

   #-#-#-#-#-#-#-#-#-#-#
   # Profile Box       #
   #-#-#-#-#-#-#-#-#-#-#

   my $profileBox = new Gtk2::HBox(FALSE, 5);

   # create a new Gtk2::SimpleList object
   #
   $list = new Gtk2::SimpleList(
      '     ' => 'pixbuf',
      'Profile' => 'text',
      'Access Point' => 'text',
   );

   # set any properties on new list
   #
   #$list->get_selection()->set_mode('multiple');
   #$list->set_reorderable(TRUE);
   $list->get_selection()->set_mode('single');
   $list->set_rules_hint(TRUE);

   # get all profiles from the model and add to profile list
   #
   push @{$list->{data}}, $I->_populateList($model);

   # create new up/down buttons to move profiles in list
   #
   my $buttonBox = new Gtk2::VButtonBox();
   $up = new_with_label Gtk2::Button("up");
   $down = new_with_label Gtk2::Button("down");
   $buttonBox->pack_start($up, FALSE, FALSE, 0);
   $buttonBox->pack_end($down, FALSE, FALSE, 0);
   $buttonBox->set_layout('spread');
   $buttonBox->set_spacing_default(5);
   
   my $profileWidgets = new Gtk2::HBox(FALSE, 5);
   $profileWidgets->pack_start($list, TRUE, TRUE, 0);
   $profileWidgets->pack_start($buttonBox, FALSE, FALSE, 0);

   my $profileHBox = new Gtk2::HBox(FALSE, 10);
   my $profileVBox = new Gtk2::VBox(FALSE, 0);
   $profileHBox->pack_start($profileWidgets, TRUE, TRUE, 10);
   $profileVBox->pack_start($profileHBox, TRUE, TRUE, 5);
   
   # set action listeners...
   #
   $up->signal_connect("clicked", sub { $I->{"controller"}->buttonHandler(@_, $list); });
   $down->signal_connect("clicked", sub { $I->{"controller"}->buttonHandler(@_, $list); });
   $list->signal_connect("row-activated", sub { $I->{"controller"}->listHandler("row-activated", @_); });

   $profileBox->pack_start($profileVBox, TRUE, TRUE, 0);

   # store any widgets that will be needed later...
   #
   $I->{"list"} = $list;

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

sub _populateList
{
   my ($I) = @_;
   my $model = Class::WirelessApp->getModel();
   
   my @Profiles = ();
   foreach my $profile ($model->getProfiles())
   {
      my $pix;
      if(grep{ $profile->get("essid") eq $_; } $model->getAvailableNetworks())
      {
         $pix = $model->isConnected() && $model->getConnectedAP()->get("essid") eq $profile->get("essid")
            ? new_from_file Gtk2::Gdk::Pixbuf("images/connected.gif")
            : new_from_file Gtk2::Gdk::Pixbuf("images/available.gif");
      }
      else
      {
         $pix = new_from_file Gtk2::Gdk::Pixbuf("images/unavailable.gif");
      }
      
      push @Profiles, [$pix, $profile->get("name"), $profile->get("essid")];
   }

   return @Profiles;
}

1;#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#
