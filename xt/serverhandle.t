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
            xref_response( { url => '/foo', text => 'This is a foo' } ),
        }

        ],

    client => sub {
        my ( $mech, $server ) = @_;
        my $handle = Ambikon::ServerHandle->new( base_url => 'http://localhost:'.$server->port.'/ambikon' );
        my $data = $handle->search_xrefs( 'fogbat' );
        is $data->{fogbat}{foo_bar}{xrefs}[0]{text}, 'This is a foo',
           'got the right xref data back';
    },
);

done_testing;



sub xref_response {
    return [ 200,
             [],
             [JSON->new->convert_blessed->encode([
                 map {
                     Ambikon::Xref->new( %$_ )
                 } @_
              ])
             ],
           ];
}
