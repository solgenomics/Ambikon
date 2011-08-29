package Ambikon::ServerHandle;
# ABSTRACT: object for dealing with an Ambikon Integration Server

use Moose;
use namespace::autoclean;
use MooseX::Types::URI 'Uri';

use Ambikon::Subsite;
use Ambikon::Xref;
use Ambikon::XrefSet;

=attr base_url

The base URL at which to access ambikon API functions on the server.

Defaults to the value of the C<HTTP_X_AMBIKON_SERVER_URL> environment
variable, if set, otherwise defaults to '/ambikon'.

Note that C<HTTP_X_AMBIKON_SERVER_URL> is the value of the incoming
request's X-Ambikon-Server-Url header, if running under CGI.

=cut

has 'base_url' => (
    is       => 'ro',
    isa      => Uri,
    coerce   => 1,
    default  => sub { $ENV{HTTP_X_AMBIKON_SERVER_URL} || '/ambikon' },
   );

# cached useragent obj
has '_ua' => (
    is  => 'ro',
    isa => 'Object',
    lazy_build => 1,
    );
sub _build__ua { Class::MOP::load_class('LWP::UserAgent');  LWP::UserAgent->new }

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

my $json;
sub search_xrefs {
    my $self = shift;
    my %args = @_ == 1 ? ( queries => \@_ ) : @_;

    $json ||= do {
        Class::MOP::load_class('JSON');
        JSON->new;
    };

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

    return $self->inflate_xref_search_result( $data );
}

=method inflate_xref_search_result

=cut

# inflate XrefSet, Xref, and Subsite objects in the returned data
sub inflate_xref_search_result {
    my ( $self, $data ) = @_;

    for my $query_results ( values %$data ) {
        for my $subsite_results ( values %$query_results ) {

            # inflate subsite if necessary
            my $subsite = $subsite_results->{subsite};
            if( $subsite && !blessed $subsite ) {
                $subsite = $subsite_results->{subsite} = Ambikon::Subsite->new( $subsite_results->{subsite} );
            }

            # skip this result if no xref set, but don't inflate the
            # set yet, because need to inflate the Xrefs first
            my $xref_set = $subsite_results->{xref_set} or next;

            # inflate each of the xrefs in the set
            my $xrefs = blessed $xref_set ? $xref_set->xrefs : $xref_set->{xrefs} || [];
            for my $xref ( @$xrefs ) {
                if( not blessed $xref ) {
                    $xref = Ambikon::Xref->new( { %$xref, subsite => $subsite } );
                }
            }

            # finally, inflate the xref set
            if( not blessed $subsite_results->{xref_set} ) {
                $xref_set = $subsite_results->{xref_set} = Ambikon::XrefSet->new( { %$xref_set, subsite => $subsite } );
            }
        }
    }

    return $data;
}

__PACKAGE__->meta->make_immutable;
1;
