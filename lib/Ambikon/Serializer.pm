package Ambikon::Serializer;
#ABSTRACT: handler for serializing and deserializing Ambikon objects to and from data structures
use Moose;

use List::MoreUtils 'uniq';

use JSON; my $json = JSON->new->convert_blessed;

use Data::Visitor::Callback;

=method inflate( \%data )

Modifies the given hashref of Ambikon xref result data in-place,
inflating L<Ambikon::XrefSet>, L<Ambikon::Xref>, and
L<Ambikon::Subsite> objects from their data-structure representations
if necessary.

Ignores objects that have already been inflated.

=cut

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

=method decode_queries( \@queries )

Given an arrayref of strings, returns another arrayref containing
decoded versions of any strings it recognizes.  For example, if
passed:

  [ 'hello', 'application/json:{ "foo" : "bar" }', 'hi' ]

It will return:

  [ 'hello', { foo => 'bar' }, 'hi' ]

Returns an arrayref of strings and data structures.

=cut

sub decode_queries {
    my ( $self, $queries ) = @_;

    return [
        map {
            my $q = $_;
            if( s!^application/json:!!
                and my $decode = eval { $json->decode( $_ ) }
              ) {
                $decode
            } else {
                $q
            }
        } @$queries
    ];
}

=method encode_queries( \@queries, $preferred_content_type = 'application/json' )

The reverse of decode_queries above.

=cut

sub encode_queries {
    my ( $self, $queries, $content_type ) = @_;
    $content_type ||= 'application/json';

    my $encoder = {
        'application/json' => sub { $json->encode( @_ ) },
    }->{$content_type} or die "content type $content_type not supported";

    return [
        map { ref $_ ? $content_type.':'.$encoder->( $_ ) : $_ }
        @$queries
    ];
}

__PACKAGE__->meta->make_immutable;
1;

