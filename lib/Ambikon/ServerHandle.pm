package Ambikon::ServerHandle;
# ABSTRACT: object for dealing with an Ambikon Integration Server

use Moose;
use namespace::autoclean;
use MooseX::Types::URI 'Uri';

use Data::Visitor::Callback;
use List::MoreUtils 'uniq';

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

# per-object cached useragent obj
has '_ua' => (
    is  => 'ro',
    isa => 'Object',
    lazy_build => 1,
    );
sub _build__ua { Class::MOP::load_class('LWP::UserAgent');  LWP::UserAgent->new }

# globally cached JSON obj
{ my $json;
  has '_json' => (
      is => 'ro',
      default => sub {
          return $json ||= do {
              Class::MOP::load_class('JSON');
              JSON->new;
          }
      },
    );
}

sub _make_url {
    my ( $self, %args ) = @_;
    $args{path} = $self->base_url->path.'/'.$args{path};
    my $url = $self->base_url->clone;
    $url->path( $args{path} );
    $url->query_form( $args{query} );
    return $url;
}


=method search_xrefs_html

Request xrefs HTML from the Ambikon server.  The HTML is assembled
from either renderings provided by subsites, or from default Ambikon
renderings.

Can be called as just C<< $s->search_xrefs_html( $query ) >> for a
single query with no hints, or in a long form for more flexibility:

  $s->search_xrefs_html(
      queries => \@queries,
      hints   => {
          foo => 'bar',
      },
  )

=cut

sub search_xrefs_html {
    my $self = shift;

    my $res = $self->_xrefs_request( 'xrefs/search_html', @_ )
        or return;

    my $content = $res->content;
    if( not $res->is_success ) {
        my $url     = $res->request->uri;
        my $error   = $res->status_line;
        die "error fetching Ambikon xrefs HTML from $url ($error).  Server returned body:\n$content\n";
    }

    return $content;
}

=method search_xrefs

Request xrefs JSON from the Ambikon server.  Accepts the same
arguments as C<search_xrefs_html> above.  Decodes the JSON response
and inflates objects (L<Ambikon::XrefSet>, etc).  Returns nothing if
no response.

=cut

sub search_xrefs {
    my $self = shift;

    my $res = $self->_xrefs_request( 'xrefs/search', @_ )
        or return;

    my $data = $res->is_success && eval { $self->_json->decode( $res->content ) };
    if( not $data ) {
        my $url = $res->request->uri;
        if( $@ ) {
            die "error fetching Ambikon xrefs from $url: $@\n";
        } else {
            die "error fetching Ambikon xrefs from $url, server returned ".$res->status_line." with content: ".$res->content;
        }
    }

    return $data;
}

=method inflate( \%data )

Modifies the given hashref of Ambikon xref result data in-place,
inflating L<Ambikon::XrefSet>, L<Ambikon::Xref>, and
L<Ambikon::Subsite> objects from their data-structure representations
if necessary.

Ignores objects that have already been inflated.

=cut

*inflate_xref_search_result = \&inflate;

sub inflate {
    my ( $self, $data, $extra_data ) = @_;
    # shallow-clone extra_data so we can modify it
    $extra_data = { %{ $extra_data || {} } };

    Data::Visitor::Callback
        ->new(
            ignore_return_values => 1,
            array => sub {
                my ( $v, $ar ) = @_;
                for ( @$ar ) {
                    $v->visit( $_ );
                    if ( my $i = $self->_inflate( $extra_data, $_ ) ) {
                        $_ = $i;
                    }
                }
            },
            hash  => sub {
                my ( $v, $hr ) = @_;
                # NOTE: code below is complicated a bit by the need to
                # make sure we inflate the subsite first, if present,
                # so we can pass it to any other inflated objects as
                # an attribute
                for my $k ( uniq 'subsite', keys %$hr) {
                    next unless $hr->{$k};

                    $v->visit( $hr->{$k} );
                    if ( my $i = $self->_inflate( $extra_data, $hr->{$k} ) ) {
                        $hr->{$k} = $i;
                    }
                    if( $k eq 'subsite' ) {
                        $extra_data->{subsite} = $hr->{$k};
                    }
                }
            },
          )
        ->visit( $data );

    return $data;
}

sub _inflate {
    my ( $self, $extra, $obj ) = @_;

    ref $obj eq 'HASH' and ( my $classes = $obj->{__CLASS__} )
        or return;

    $classes = [$classes] unless ref $classes;

    my $error;
    for my $class ( @$classes ) {
        # load the most specific class that we can
        eval { Class::MOP::load_class( $class ) };
        if( $@ ) { $error = $@; next }
        my $thawed = eval { $class->thaw( { %$extra, %$obj } ) };
        if( $@ ) { $error = $@; next }
        return $thawed;
    }

    warn "warning, could not inflate object: $error";
    return $obj;
}

######## helper methods #########

sub _xrefs_request {
    my $self = shift;
    my $path = shift;
    my %args = @_ == 1 ? ( queries => \@_ ) : @_;

    my @queries = map {
            ref $_ ? $self->_json->encode( $_ ) : $_
        } @{$args{queries} || [] };

    return unless $args{queries} && @{$args{queries}};

    my $url = $self->_make_url(
        path  => $path,
        query => {
            q => \@queries,
            %{ $args{hints} || {} },
        },
       );

    return $self->_ua->get( $url );
}



__PACKAGE__->meta->make_immutable;
1;
