package Ambikon::ServerHandle;
# ABSTRACT: object for dealing with an Ambikon Integration Server

use Moose;
use namespace::autoclean;
use MooseX::Types::URI 'Uri';

use JSON (); my $json = JSON->new;
use LWP::UserAgent ();
use URI::FromHash ();

use Ambikon::Subsite;
use Ambikon::Xref;
use Ambikon::XrefSet;

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

Accepts just C<< ( $query ) >> for a single query with no hints, or the long
form C<< ( queries => \@queries, hints => { foo => 'bar' } ) >>.

Returns a data structure like:

  TODO document data structure

=cut

sub search_xrefs {
    my $self = shift;
    my %args = @_ == 1 ? ( queries => \@_ ) : @_;

    my @queries = map {
        ref $_ ? $json->encode( $_ ) : $_
    } @{$args{queries} || [] };

    return {} unless @queries;

    my $hints = $args{hints};

    my $url = $self->_make_url(
        path  => 'xrefs/search',
        query => {
            q => \@queries,
            %{ $hints || {} },
        },
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

    use Data::Dump;
    dd( $data );

    # inflate XrefSet, Xref, and Subsite objects in the returned data
    for my $query_results ( values %$data ) {
        for my $subsite_results ( values %$query_results ) {
            my $subsite = $subsite_results->{subsite} &&= Ambikon::Subsite->new( $subsite_results->{subsite} );

            my $xref_set = $subsite_results->{xref_set}
                or next;
            for my $xref ( @{$xref_set->{xrefs} || [] } ) {
                $xref = Ambikon::Xref->new( { %$xref, subsite => $subsite } );
            }
            $subsite_results->{xref_set} = Ambikon::XrefSet->new( $xref_set );
        }
    }

    return $data;
}

__PACKAGE__->meta->make_immutable;
1;
