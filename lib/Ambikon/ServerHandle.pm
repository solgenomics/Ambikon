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
sub _build__ua { LWP::UserAgent->new }

sub _make_url {
    my ( $self, %args ) = @_;
    $args{path} = $self->base_url->path.'/'.$args{path};
    my $url = $self->base_url->clone;
    $url->path( $args{path} );
    $url->query_form( $args{query} );
    return $url;
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

    my $url = $self->_make_url(
        path  => 'xrefs/search',
        query => { q => \@queries },
       );
    my $res = $self->_ua->get( $url );

    my $data = $res->is_success && eval { $json->decode( $res->content ) };
    if( not $data ) {
        if( $@ ) {
            die "error fetching Ambikon xrefs from $url: $@\n";
        } else {
            die "error fetching Ambikon xrefs from $url, server returned ".$res->status_line." with content: ".$res->content;
        }
    }

    # go through and inflate all the objects

    return $data;
}

__PACKAGE__->meta->make_immutable;
1;
