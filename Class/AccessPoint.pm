#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#
#
#   Class:          AccessPoint.pm
#
#   Author:         Kier Elliott
#
#   Date:           08/15/2004
#
#   Description:    AccessPoint is used to provide a encapsulated
#                   vessel in which to store all information regarding
#                   a given access point.  The object is very simple,
#                   providing methods to get and set data regarding
#                   and access point.
#
#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#

package Class::AccessPoint;

use strict; use warnings;

# overload the "" operator so that when an AccessPoint
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
   my ($class) = @_;
   my $this = {};

   # bless this object into given class 
   #
   bless $this, $class;

   # initialize object values with given data
   #
   $this->{"essid"}       = "",
   $this->{"address"}     = "",
   $this->{"mode"}        = "",
   $this->{"encryption"}  = "",
   $this->{"protocol"}    = "",
   $this->{"noiseLevel"}  = "",
   $this->{"bitRate"}     = (),
   $this->{"signalLevel"} = "",
   $this->{"frequency"}   = "",
   $this->{"quality"}     = "",
   
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

   return $old; # may be undef!
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
      $value .= $var eq "bitRate"
         ? "   " . $var . " => (" . join(",", @{$I->{$var}}) . ") MB/s\n"
         : "   " . $var . " => " . $I->{$var} . "\n"; 
   }
   $value .= " ]\n";

   return $value;
}

1;#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#
