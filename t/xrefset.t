use strict;
use warnings;

use Test::More;

use_ok( 'Ambikon::XrefSet' );

my $xrs = Ambikon::XrefSet->new();

my $j = $xrs->TO_JSON;
is $j->{'__CLASS__'}->[0], 'Ambikon::XrefSet', 'got class in serialization';

#diag explain $j;

done_testing;
