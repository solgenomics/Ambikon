package Ambikon::ServerHandle;
# ABSTRACT: object for dealing with an Ambikon Integration Server

use Moose;
use namespace::autoclean;
use MooseX::Types::URI 'Uri';

use JSON (); my $json = JSON->new;
use LWP::UserAgent ();
use URI::FromHash ();

=attr base_url

The base URL at which to access ambikon API functions on the server.
defaults to '/ambikon'

=cut

has 'base_url' => (
    is       => 'ro',
    isa      => Uri,
    coerce   => 1,
    default  => '/ambikon',
   );

# cached useragent obj
has '_ua' => (
    is  => 'ro',
    isa => 'Object',
    lazy_build => 1,
    );
sub _build_ua { LWP::UserAgent->new }

# convenience method to do an GET with a path relative to the ambikon
# base path and with a Content-Type header set requesting a JSON
# response
sub _get {
    my ( $self, %args ) = @_;
    $args{path} = $self->base_url.'/'.$args{path};
    my $url = URI::FromHash::uri( %args );
    return $self->_ua->get( $url, 'Content-Type' => 'application/json' );
}


=method search_xrefs

Request xrefs from the Ambikon server.

Returns a data structure like:

  TODO document data structure

=cut

sub search_xrefs {
    my $self = shift;

    my @queries = map {
        ref $_ ? $json->encode( $_ ) : $_
    } @_;

    my $res = $self->_get( path  => 'xrefs/search',
                           query => { q => \@queries } );

    my $data = $res->is_success && eval { $json->decode( $res->content ) };
    if( not $data ) {
        if( $@ ) {
            die "error fetching Ambikon xrefs, cannot parse server response: $@";
        } else {
            die "error fetching Ambikon xrefs, server returned ".$res->status_line." with content: ".$res->content;
        }
    }

    # go through and inflate all the objects

    return $data;
}

__PACKAGE__->meta->make_immutable;
1;
