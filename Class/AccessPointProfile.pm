#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#
#
#   Class:          AccessPointProfile.pm
#
#   Author:         Kier Elliott
#
#   Date:           08/24/2004
#
#   Description:    AccessPointProfile is a data object that is used
#                   to store the necessary data to connect to a particular
#                   Access Point.
#
#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#

package Class::AccessPointProfile;

use strict; use warnings;

# overload the "" operator so that when an AccessPointProfile
# object is passed to print method, a nicely formatted
# string is returned rather than a pointer string
#
use overload
      '""' => \&print;

##################
# public methods #
##################

# model constructor
#
sub new
{
   my ($class, %data) = @_;
   my $this = {};

   # bless this object into given class 
   #
   bless $this, $class;

   # initialize object values with given data
   #
   $this->{"name"}       = $data{"name"};
   $this->{"essid"}      = $data{"essid"};
   $this->{"mode"}       = $data{"mode"} || "";
   $this->{"encryption"} = $data{"encryption"} || "";
   $this->{"key"}        = $data{"key"} || "";
   $this->{"_dump"}   = 0;

   return $this;
}

# get a property - read only
#
sub get
{
   my ($I, $property) = @_;
   
   return $I->{$property} if exists $I->{$property};
   
   return undef;   # no such property!
}
   
# set a property - return the old value
#
sub set
{
   my ($I, $property, $value) = @_;

   my $old = $I->{$property} if exists $I->{$property};
   $I->{$property} = $value;

   # set modified value to true to reflect modified state
   #
   $I->{"_dump"} = 1 if $property ne "_dump";

   return $old; # may be undef!
}

sub setModified
{
   my ($I, $value) = @_;

   $I->{"_dump"} = $value;
}

sub isModified
{
   my ($I) = @_;

   return $I->{"_dump"};
}

# This method overloads the "" operator.  This allows a user
# to print an AccessPoint object and get a relevant string
# representation returned.
#
sub print
{
   my ($I) = @_;
   my $value = "";

   $value .= " [\n";
   foreach my $var (keys %$I)
   {
      $value .= "   " . $var . " => " . $I->{$var} . "\n"; 
   }
   $value .= " ]\n";

   return $value;
}

1;#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#
