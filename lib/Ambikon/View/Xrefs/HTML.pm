=head1 NAME

Ambikon::View::Xrefs::HTML - default HTML view for xref responses,
xref sets, and single xrefs

=cut

package Ambikon::View::Xrefs::HTML;
use Moose;
use namespace::autoclean;

use Scalar::Util 'blessed';
use List::MoreUtils 'uniq';

sub join_lines(@) {
    join '', map "$_\n", @_
}

sub xref_response_html {
    my ( $self, $response ) = @_;

    return $response->{renderings}{'text/html'}
        if $response->{renderings}{'text/html'};

    my $whole_body = join_lines (
        qq|<dl class="ambikon_xref ambikon">|,
        ( map {
            my $query = $_;
            my $v = $response->{$_};
            $self->_response_query_html( $_, $response->{$_} );
          } sort grep !$self->_reserved_key( $_ ), keys %$response,
        ),
        qq|</dl>|,
      );

    return $whole_body;
}

sub _response_query_html {
  my ( $self, $query, $v ) = @_;

  my @results = map {
      my $subsite_name = $_;
      $v = $v->{$subsite_name};
      if( my $xrefs = $v->{xref_set} ) {
          $self->xref_set_html( $xrefs );
      } else {
          ()
      }
  } sort keys %$v;

  return unless @results;
  return ( qq|   <dt class="ambikon_xref ambikon">$query</dt>|,
           qq|       <dd>|,
           @results,
           qq|       </dd>|,
         );
}


sub _reserved_key {
    return {
        renderings => 1
    }->{ $_[1] } || 0;
}

sub xref_set_html {
    my ( $self, $set ) = @_;

    # use the xref set's rendering if it has one
    # otherwise make a default one
    my $pre_rendered = $self->_get( $set, 'renderings' )->{'text/html'};
    return $pre_rendered if $pre_rendered;

    my @xrefs = uniq( map "<li>".$self->xref_html( $_ )."</li>", @{ $self->_get($set, 'xrefs' ) } );
    return unless @xrefs;

    return join '', map "$_\n", (
               '<div class="ambikon_xref_set ambikon">',
               '<ul>',
               @xrefs,
               '</ul>',
               '</div>',
             );

}
sub xref_html {
    my ( $self, $xref ) = @_;

    my $pre_rendered = $self->_get( $xref, 'renderings' )->{'text/html'};
    return $pre_rendered if $pre_rendered;
    my $url  = $self->_get( $xref, 'url' );
    my $text = $self->_get( $xref, 'text' );
    return qq|<a class="ambikon_xref ambikon" href="$url">$text</a>|;
}

sub _get {
    my ( $self, $thing, $attribute ) = @_;
    return $thing->{$attribute} if ref $thing eq 'HASH';
    no strict 'refs';
    return $thing->$attribute();
}

1;
