#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#
#
#   Name:          Class::View::Main
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
   my ($menu, $status, $command, $profile) = $I->_constructView();

   # add all widgets to main box...
   #
   $mainBox->pack_start($menu->{widget}, FALSE, FALSE, 0);
   $mainBox->pack_start($status, FALSE, FALSE, 10);
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

   # update connection status information
   #
   if( my $accessPoint = $model->getConnectedAP() )
   {
      $I->{"status"}->set_label(
         $model->isConnected()
            ? "Connected"
            : "Disconnected"
      );
      $I->{"essid"}->set_label($accessPoint->get("essid"));
      $I->{"encryption"}->set_label($accessPoint->get("encryption"));
   }

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
   # Status Box        #
   #-#-#-#-#-#-#-#-#-#-#

   my $statusFrame = $I->_constructStatus($model->getConnectedAP());
   my $statusVBox = new Gtk2::VBox(FALSE, 0);
   my $statusBox = new Gtk2::HBox(FALSE, 0);
   $statusVBox->pack_start($statusFrame, TRUE, TRUE, 0);
   $statusBox->pack_start($statusVBox, TRUE, TRUE, 10);
         
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
   return ($menu, $statusBox, $commandBox, $profileBox);
}

sub _constructStatus
{
   my ($I, $accessPoint) = @_;
   my $model = Class::WirelessApp->getModel();
   my %appConfigs = Class::WirelessApp->getConfig();
   my $status = new Gtk2::Label("Disconnected");
   my $ap = new Gtk2::Label();
   my $encryption = new Gtk2::Label();

   if($model->isConnected())
   {
      $status->set_label("Connected");
      $ap->set_label($accessPoint->get("essid"));
      $encryption->set_label($accessPoint->get("encryption"));
   }

   # create strength widgets...
   #
   my $gVBox = new Gtk2::VBox(FALSE, 0);
   my $gHBox = new Gtk2::VBox(FALSE, 0);
   my $strength = new_from_file Gtk2::Image($appConfigs{"images"}{"strength"}{"large"}[0]);
   $gHBox->pack_start($strength, FALSE, FALSE, 0);
   $gVBox->pack_start($gHBox, FALSE, FALSE, 2);
   
   # create Status widgets...
   #
   my $statusLabelBox = new Gtk2::HBox(FALSE, 0);
   my $statusBox = new Gtk2::HBox(FALSE, 0);
   my $sVBox = new Gtk2::VBox(FALSE, 0);
   my $sHBox = new Gtk2::HBox(FALSE, 0);
   $statusLabelBox->pack_end(new Gtk2::Label("Status:"), FALSE, FALSE, 0);
   $statusBox->pack_end($status, FALSE, FALSE, 0);
   $sHBox->pack_start($statusLabelBox, FALSE, FALSE, 5);
   $sHBox->pack_start($statusBox, FALSE, FALSE, 5);
   $sVBox->pack_start($sHBox, FALSE, FALSE, 5);
   
   # create AccessPoint widgets...
   #
   my $apLabelBox = new Gtk2::HBox(FALSE, 0);
   my $apBox = new Gtk2::HBox(FALSE, 0);
   my $aVBox = new Gtk2::VBox(FALSE, 0);
   my $aHBox = new Gtk2::HBox(FALSE, 0);
   $apLabelBox->pack_end(new Gtk2::Label("Access Point:"), FALSE, FALSE, 0);
   $apBox->pack_end($ap, FALSE, FALSE, 0);
   $aHBox->pack_start($apLabelBox, FALSE, FALSE, 5);
   $aHBox->pack_start($apBox, FALSE, FALSE, 5);
   $aVBox->pack_start($aHBox, FALSE, FALSE, 5);

   # create Encryption widgets...
   #
   my $encryptionLabelBox = new Gtk2::HBox(FALSE, 0);
   my $encryptionBox = new Gtk2::HBox(FALSE, 0);
   my $eVBox = new Gtk2::VBox(FALSE, 0);
   my $eHBox = new Gtk2::HBox(FALSE, 0);
   $encryptionLabelBox->pack_end(new Gtk2::Label("Encryption:"), FALSE, FALSE, 0);
   $encryptionBox->pack_end($encryption, FALSE, FALSE, 0);
   $eHBox->pack_start($encryptionLabelBox, FALSE, FALSE, 5);
   $eHBox->pack_start($encryptionBox, FALSE, FALSE, 5);
   $eVBox->pack_start($eHBox, FALSE, FALSE, 5);

   my $hBox = new Gtk2::HBox(FALSE, 0);
   my $vBox = new Gtk2::VBox(FALSE, 0);
   $vBox->pack_start($sVBox, FALSE, FALSE, 0);
   $vBox->pack_start($aVBox, FALSE, FALSE, 0);
   $vBox->pack_start($eVBox, FALSE, FALSE, 0);
   $hBox->pack_start($vBox, FALSE, FALSE, 0);

   my $layout = new Gtk2::HBox(FALSE, 0);
   $layout->pack_start($gVBox, FALSE, FALSE, 0);
   $layout->pack_start($hBox, FALSE, FALSE, 0);
   
   # create new frame...
   #
   my $frame = new Gtk2::Frame(" Status ");
   $frame->add($layout);

   # save labels for later use...
   #
   $I->{"strength"} = $strength;
   $I->{"status"} = $status;
   $I->{"essid"} = $ap;
   $I->{"encryption"} = $encryption;

   return $frame;
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
   my %appConfigs = Class::WirelessApp->getConfig();
   
   my @Profiles = ();
   foreach my $profile ($model->getProfiles())
   {
      my $pix = undef;
      if(grep{ $profile->get("essid") eq $_; } $model->getAvailableNetworks())
      {
         $pix = $model->isConnected() && $model->getConnectedAP()->get("essid") eq $profile->get("essid")
            ? new_from_file Gtk2::Gdk::Pixbuf($appConfigs{"images"}{"connected"})
            : new_from_file Gtk2::Gdk::Pixbuf($appConfigs{"images"}{"available"});
      }
      
      push @Profiles, [$pix, $profile->get("name"), $profile->get("essid")];
   }

   return @Profiles;
}

1;#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#
