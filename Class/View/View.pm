#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#
#
#   Class:          View.pm
#
#   Author:         Kier Elliott
#
#   Date:           08/22/2004
#
#   Description:    The View.pm class is essentially an abstract class.
#                   It is a parent to all object view classes providing
#                   default implementations for required methods.
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

package Class::View;

use strict; use warnings;

##################
# public methods #
##################

sub new
{
   my ($class, $controller) = @_;
   my $this = {};

   # bless this object into given class
   #
   bless $this, $class;

   # declare all class variables and set controller 
   # variable using given reference
   #
   $this->{"controller"} = $controller;

   return $this;
}

# this method MUST be updated in each child class
# to reflect that classes usage of the model data
#
sub update
{
   my ($I) = @_;

   print "Updating View data...\n";
}

sub getController
{
   my ($I) = @_;

   return $I->{"controller"};
}

1;#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#
