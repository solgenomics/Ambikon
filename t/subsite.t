use strict;
use warnings;

use Test::More;

use Ambikon::Subsite;

my $ss = Ambikon::Subsite->new(
    shortname => 'foo',
    name => 'Foo Special Tool',
    internal_url => 'http://localhost:2121',
    external_path => '/bonk',
  );

can_ok $ss, qw/shortname name internal_url external_path/;



done_testing;
