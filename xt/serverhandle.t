use strict;
use warnings;

use Test::More;
use JSON;

use lib 't/lib';
use lib 'xt/ais_t_lib';
use lib 'xt/ais_lib';

use Ambikon::IntegrationServer::Test::Constellation qw/ test_constellation /;

use Ambikon::Xref;
use Ambikon::ServerHandle;

test_constellation(
    conf => <<'',
<subsite foo_bar>
  internal_url   http://$host:$port/monkeys
  external_path  /foo
</subsite>

    backends => [
        sub {
            xref_response( { url => '/foo', text => 'This is a foo', renderings => { 'text/html' => 'FAKE HTML' } } ),
        }

        ],

    client => sub {
        my ( $mech, $server ) = @_;
        my $handle = Ambikon::ServerHandle->new( base_url => 'http://localhost:'.$server->port.'/ambikon' );
        my $data = $handle->search_xrefs( queries => ['fogbat'], hints => { noggin => 1 } );
        #diag explain $data;
        is $data->{fogbat}{foo_bar}{xref_set}->xrefs->[0]->text, 'This is a foo',
           'got the right xref data back';

        # test a flat_array data format
        $data = $handle->search_xrefs( queries => ['fogbat'], hints => { format => 'flat_array' } );
        is ref $data, 'ARRAY', 'flat_array returns an arrayref';
        is $data->[0]->tags->[0], 'foo_bar';
        #diag explain $data;

        $data = $handle->search_xrefs();
        is $data, undef, 'got undef from search_xrefs with no args';

        my $html = $handle->search_xrefs_html( 'fogbat' );
        #diag $html;
        like $html, qr!FAKE HTML!, "got xref's HTML rendering";

    },
);

done_testing;


sub xref_response {
    return [
        200,
        [],
        [ JSON->new->convert_blessed->encode(
            Ambikon::XrefSet->new( [
                map {
                    Ambikon::Xref->new( %$_ )
                } @_
            ])
          )
        ],
  ];
}
