package IOException;

use base qw(Error);
use overload ('""' => 'stringify');

1;#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#

#sub new
#{
#  my $self = shift;
#  my $text = "" . shift;
#  my @args = ();
#
#  local $Error::Depth = $Error::Depth + 1;
#  local $Error::Debug = 1;  # Enables storing of stacktrace
#
#  $self->SUPER::new(-text => $text, @args);
#}
#1;
	  
#package DivideByZeroException;
#use base qw(MathException);
#1;
#
#package OverFlowException;
#use base qw(MathException);
#1;
