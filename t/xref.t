use strict;
use warnings;

use Test::More;
use Test::MockObject;

use Ambikon::Subsite;

use_ok( 'Ambikon::Xref' );

my $mock_subsite = Test::MockObject->new;
$mock_subsite->set_always( 'name', 'fakesubsite' );

my $cr1 = Ambikon::Xref->new({
    url  => '/foo/bar.txt',
    text => 'Noggin',
    subsite => $mock_subsite,
});

my $cr2 = Ambikon::Xref->new({
    url  => '/foo/bar.txt',
    text => 'Noggin',
    subsite => $mock_subsite,
});

my $cr3 = Ambikon::Xref->new({
    url  => '/foo/baz.txt',
    text => 'Noggin',
    subsite => $mock_subsite,
});

ok(   $cr2->xref_eq( $cr1 ), 'cr eq finds equal'     );
ok( ! $cr2->xref_eq( $cr3 ), 'cr eq finds not equal' );

is( $cr2->xref_cmp( $cr1 ),  0, 'cr cmp for eq' );
is( $cr2->xref_cmp( $cr3 ), -1, 'cr cmp 1' );
is( $cr3->xref_cmp( $cr1 ),  1, 'cr cmp 2' );

my @u = $cr1->uniq( $cr2, $cr3 );
is( scalar(@u), 2, 'uniq seems to work 0' );
is( $cr1,   $u[0], 'uniq seems to work 1' );
is( $cr3,   $u[1], 'uniq seems to work 2' );

my $js_hash = $cr3->TO_JSON;
is( $js_hash->{text}, 'Noggin' );
is( $js_hash->{url}, '/foo/baz.txt' );
is( $js_hash->{__CLASS__}->[0], 'Ambikon::Xref' );
ok( !exists $js_hash->{subsite}, 'no subsite' );

done_testing;
