#!/usr/bin/perl -W

#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#
#
# Purpose:  MainView.pm test file
#
# Author:   Kier Elliott
#
# Date:     08/23/2004
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
use Class::MainView;

# global variables
#

# create a new model object...
#
my $model = new Class::Model("wlan0");

# create a new view object...
#
my $view = new Class::MainView($model);

# test getModel method...
#
my $temp = $view->getModel();
$model == $temp
   ? print "getModel test...OK\n"
   : print "getModel test...FAILED\n";

# test update method...
#
print "update test ...\n";
$model->registerView($view);
$model->scan();

# test init method...
#
$view->init();

Gtk2->main();
