
package IOException;

use strict; use warnings;

use base qw(Error);
use overload
   '""' => \&print;

# declare parent classes
#
our @ISA = ("Error");

##################
# public methods #
##################

sub new
{
   my ($class, $text, @Args) = @_;
   $text ||= "";

   local $Error::Depth = $Error::Depth + 1;
   local $Error::Debug = 1; # enables storing of stacktrace

   $class->SUPER::new(-text => $text, @Args);
}

1;#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#
