#!/usr/bin/perl -W

#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#
#
# Purpose:  Connection.pm test file
#
# Author:   Kier Elliott
#
# Date:     09/07/2004
#
#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#
#
#   Subversion Info:
#     $LastChangedBy: kierse $
#     $Date: 2004-09-01 22:15:57 -0600 (Wed, 01 Sep 2004) $
#     $Rev: 6 $
#     $URL: svn+ssh://zeus/var/svn/wireless_app/trunk/stub/model_stub.pl $
#
#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#

use strict; use warnings;

use lib "..";
use Class::Connection;

my %Params = (
   mode => "Managed",
   essid => "Olympus", 
   encryption => "on",
   key => "08493232EF7015982EF3B38A9B",
);

my $connection = new Class::Connection();
$connection->init("wlan0");

print "connecting...\n";
$connection->connect(%Params);

print "sleeping for 30 seconds, go test the connection!\n";
sleep 30;

print "disconnecting...\n";
$connection->disconnect();

print "sleeping for 30 seconds, go test the connection!\n";
sleep 30;

print "connecting again!\n";
$connection->connect(%Params);
