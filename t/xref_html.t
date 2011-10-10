use strict;
use warnings;
use Test::More;
use Test::Warn;

use JSON ();
my $json = JSON->new;

use Ambikon::XrefSet;
use Ambikon::Xref;
use Ambikon::Xref::Inflator;
my $inflator = Ambikon::Xref::Inflator->new;

use_ok('Ambikon::View::Xrefs::HTML');
my $v = Ambikon::View::Xrefs::HTML->new;

my $test_response_1 = {
    foo => {
        'Bar Site' =>  {
            xref_set => Ambikon::XrefSet->new(
                xrefs => [
                    Ambikon::Xref->new(
                        text => 'Hi there',
                        url => '/hi/there',
                    ),
                ],
            ),
         },
    },
};

my $r_html = $v->xref_response_html( $test_response_1 );
like( $r_html, qr/Hi there/, 'tiny response rendered' );

my $test_response_2;
warning_like {
    $test_response_2 = $inflator->inflate( $json->decode( slurp( 't/data/xref_test_response_1.json' ) ) );
} qr!could not inflate object.+GBrowse/DataSource\.pm!, 'got an inflation warning';

#diag explain $test_response_2;
$r_html = $v->xref_response_html( $test_response_2 );
like( $r_html, qr/Genetic loci/ );
like( $r_html, qr/Genome browser/ );
like( $r_html, qr/locus_display\.pl/ );
#diag $r_html;

done_testing;

sub slurp {
    open my $f, '<', $_[0] or die "$! opening $_[0]";
    local $/;
    return scalar <$f>
}
