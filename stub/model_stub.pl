#!/usr/bin/perl -W

#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#
#
# Purpose:  Model.pm test file
#
# Author:   Kier Elliott
#
# Date:     08/12/2004
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

use strict; use warnings;

use FindBin qw($Bin);
use lib "$Bin/../";

use Class::WirelessApp;
use Class::Model;
use Class::AccessPoint;
use Class::AccessPointProfile;
use Error qw(:try);

# global variables
#
my $mac_address = "00:0F:66:36:C0:84";
my $essid = "Olympus";

# create new wireless object...
#
my $wireless = new Class::WirelessApp($Bin);
my %Config = $wireless->getConfig();

# create a new model object...
#
my $model = new Class::Model($Config{"configDir"});

try
{
   $model->init();
}
catch Error with
{
   my ($err, $ref) = @_;

   print "\nError: ";
   print $err;
   exit;
};

# test if config variables were properly set
#
print "\ntesting config variables...\n";
print "profileDir => '" . $model->getProfileDir() . "'\n";
#print "startupScript => '" . $model->getStartupScript() ."'\n";
print "\n";

# test if profiles were successfully loaded
#
print "testing _loadProfiles()...\n";
foreach my $profile ($model->getProfiles())
{
   print $profile->print();
}
print "\n";

# test scan
#
print "testing scan...\n";
$model->scan();
print "\n";

# test getAvailableAPs
#
print "testing getAvailableAPs...\n";
my %APs = $model->getAvailableAPs();
my @Keys = keys %APs;
my $list = $APs{$Keys[0]};
push @{$list}, $$list[0];
$APs{$Keys[0]} = $list;
foreach my $t (keys %APs)
{
	print $t . " => \n";
	print "[\n";
	foreach my $a ( @{$APs{$t}} )
	{
		print $a;
	}
	print "]\n\n";
}

# test getAvailableNetworks
#
print "testing getAvailableNetworks...\n";
my @APs = $model->getAvailableNetworks();
foreach my $ap (@APs)
{
	print $ap . "\n";
}
print "\n";

## test getAPData
##
#print "testing getAPData...\n";
#my %ApData = $model->getAPData();
#foreach my $s (keys %ApData)
#{
#   print $s . " =>\n";
#   print $ApData{$s} . "\n";
#}

# test getAPBySid
#
print "testing getAPBySid...\n";
my @SidData = $model->getAPBySid($essid);
foreach my $ap (@SidData)
{
   print $ap . "\n";
}
print "\n";

## test overloaded "" operators
##
#print "testing overloaded \"\" operators...\n";
#foreach my $ap ($model->getAPData())
#{
#   print $ap . "\n";
#}

exit;

# test importing profiles...
#
print "testing importing profiles...\n";
try
{
   my @Profiles = $model->importProfiles("/home/kierse/.wireless_app/importDir");
   if(scalar @Profiles > 0)
   {
      pop(@Profiles);
      $model->loadImportedProfiles(@Profiles);
   }
}

catch Error with
{
   my ($err, $ref) = @_;

   print "\nError: ";
   print $err;
   exit;
};

# test exporting profiles...
#
print "testing exporting profiles...\n";
try
{
   my $count = $model->exportProfiles("/home/kierse/.wireless_app/exportDir", ("HOME", "ERIN"));
   print "Successfully exported $count profile(s)!\n" if $count > 0;
}

catch Error with
{
   my ($err, $ref) = @_;
   
   print "\nError: ";
   print $err . "\n";
   exit;
};
