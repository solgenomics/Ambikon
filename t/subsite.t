use strict;
use warnings;

use Test::More;

use Ambikon::Subsite;

my $ss = Ambikon::Subsite->new(
    shortname => 'foo',
    name => 'Foo Special Tool',
    internal_url => 'http://localhost:2121',
    external_path => '/bonk',
    tags  => 'fogger',
  );

can_ok $ss, qw/shortname name internal_url external_path tags/;

is( $ss->tags->[0], 'fogger', 'tags coercion works' );
ok( $ss->has_tag('fogger'), 'has_tag seems to work');
ok( !$ss->has_tag('ziggy'), 'has_tag seems to work 2');
is( $ss->description, '', 'has an empty description' );
is( ref( $ss->TO_JSON ), 'HASH', 'TO_JSON makes a hashref' );

done_testing;
