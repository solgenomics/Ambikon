use strict;
use warnings;

use Test::More;
use Test::Exception;
use Test::MockObject;

use JSON;

use_ok('Ambikon::ServerHandle');

my $mock_response = Test::MockObject->new;
$mock_response->set_always( content     => 'foo' );
$mock_response->set_always( is_success  => 0     );
$mock_response->set_always( status_line => 'test status line' );

my $mock_ua = Test::MockObject->new;
$mock_ua->set_always( 'get', $mock_response );

my $h = Ambikon::ServerHandle->new( _ua => $mock_ua, base_url => '/foobase' );

can_ok( $h, 'search_xrefs' );

throws_ok { $h->search_xrefs( 'noggin' ) } qr/error fetching/;

my $example_xref_data =
{
  'cromulence' => {
    'baz' => {
      'error_message' => 'the xref data returned from the subsite was not valid',
      'http_status' => 500,
      'malformed_result' => 'baz baby',
      'query' => 'cromulence',
      'subsite' => {
        'alias' => [],
        'description' => '',
        'external_path' => '/fog',
        'internal_url' => 'http://127.0.0.1:10109/',
        'modification' => {},
        'name' => 'baz',
        'shortname' => 'baz'
      }
    },
    'foo_bar' => {
      'http_status' => '200',
      'query' => 'cromulence',
      'result' => [
        {
          'query' => 'q=cromulence',
          'twee' => 'zee'
        }
      ],
      'subsite' => {
        'alias' => [],
        'description' => '',
        'external_path' => '/foo',
        'internal_url' => 'http://127.0.0.1:10440/monkeys',
        'modification' => {},
        'name' => 'foo_bar',
        'shortname' => 'foo_bar'
      }
    }
  },
  'monkeys' => {
    'baz' => {
      'error_message' => 'the xref data returned from the subsite was not valid',
      'http_status' => 500,
      'malformed_result' => 'baz baby',
      'query' => 'monkeys',
      'subsite' => {
        'alias' => [],
        'description' => '',
        'external_path' => '/fog',
        'internal_url' => 'http://127.0.0.1:10109/',
        'modification' => {},
        'name' => 'baz',
        'shortname' => 'baz'
      }
    },
    'foo_bar' => {
      'http_status' => '200',
      'query' => 'monkeys',
      'result' => [
        {
          'query' => 'q=monkeys',
          'twee' => 'zee'
        }
      ],
      'subsite' => {
        'alias' => [],
        'description' => '',
        'external_path' => '/foo',
        'internal_url' => 'http://127.0.0.1:10440/monkeys',
        'modification' => {},
        'name' => 'foo_bar',
        'shortname' => 'foo_bar'
      }
    }
  }
}
;

$mock_response->set_always( content    => to_json( $example_xref_data ) );
$mock_response->set_always( is_success => 1     );

my $return = $h->search_xrefs( 'noggin' );
is ref $return, 'HASH', 'got a hashref back';
is $return->{cromulence}{baz}{http_status}, 500, 'got right data back';

done_testing;


