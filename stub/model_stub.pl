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

use lib "..";
use Class::Model;
use Class::AccessPoint;
use Class::AccessPointProfile;
use Error qw(:try);

# global variables
#
my $mac_address = "";
my $essid = "";

# create a new model object...
#
my $model = new Class::Model("wlan0");

try
{
   $model->init();
   $model->scan();
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

# test getAPs
#
print "testing getAvailableAPs...\n";
my %APs = $model->getAvailableAPs();
foreach my $t (keys %APs)
{
   print $t . " => " . $APs{$t} . "\n";
}

my @Addrs = keys %APs;
$mac_address = $Addrs[0];
$essid = $APs{$mac_address};
print "\n";

# test getAPData
#
print "testing getAPData...\n";
my %ApData = $model->getAPData();
foreach my $s (keys %ApData)
{
   print $s . " =>\n";
   print $ApData{$s} . "\n";
}

# test getDataByAddress
#
print "testing getAPByAddress...\n";
my $accessPoint = $model->getAPByAddress($mac_address);
print $mac_address . " => \n";
print $accessPoint . "\n";

# test getDataBySid
#
print "testing getAPBySid...\n";
my @SidData = $model->getAPBySid($essid);
foreach my $ap (@SidData)
{
   print $ap->get('address') . " => \n";
   print $ap . "\n";
}

# test overloaded "" operators
#
print "testing overloaded \"\" operators...\n";
foreach my $ap ($model->getAPData())
{
   print $ap . "\n";
}

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
