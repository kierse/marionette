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

package Class::View;

use strict; use warnings;

##################
# public methods #
##################

sub new
{
   my ($class, $model) = @_;
   my $this = {};

   # bless this object into given class
   #
   bless $this, $class;

   # declare all class variables and set model
   # variable using given model reference
   #
   $this->{"model"} = $model;

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

sub getModel
{
   my ($I) = @_;

   return $I->{"model"};
}

1;#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#
