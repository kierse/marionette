#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#
#
#   Class:          Error::Exception
#
#   Author:         Kier Elliott
#
#   Date:           09/15/2004
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

package Error::Exception;

use strict; use warnings;

use base qw(Error);

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

package Error::IOException;
use base qw(Error::Exception);

1;#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#

package Error::FileSystemException;
use base qw(Error::Exception);

1;#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#

package Error::MissingResourceException;
use base qw(Error::Exception);

1;#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#

package Error::ExecutionException;
use base qw(Error::Exception);

1;#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#

package Error::IllegalParameterException;
use base qw(Error::Exception);

1;#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#

package Error::ParsingException;
use base qw(Error::Exception);

1;#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#

