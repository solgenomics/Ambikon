package Ambikon::XrefSet;
# ABSTRACT: container of Xrefs
use Moose;

with 'Ambikon::Role::Taggable';

=head1 DESCRIPTION

A container holding Xrefs, which might have renderings or so forth for
this set of Xrefs.

=cut

=attr xrefs

Arrayref of L<Ambikon::Xref> objects contained in this set.

=method is_empty

Convenient method to tell if the set is empty.  Returns whether this
holds no xrefs.

=cut

has 'xrefs' => (
    is  => 'rw',
    isa => 'ArrayRef[Ambikon::Xref]',
    default => sub { [] },
    traits => ['Array'],
    handles => {
        is_empty => 'is_empty',
    },
  );

=attr renderings

Hashref of renderings, keyed by Content-Type.  For example,
$set->renderings->{'text/html'} will give the set's HTML rendering, if
available.

=method rendering

Convenience for accessing a specific rendering.
C<< $set->rendering('text/html') >> is equivalent to
C<< $set->rendering->{'text/html'} >>.

=cut

has 'renderings' => (
    is => 'rw',
    isa => 'HashRef',
    default => sub { {} },
    traits => ['Hash'],
    handles => {
        rendering => 'get',
    },
);


around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    # support just being constructed with an arrayref of xrefs, in
    # which case renderings will just be empty
    if( @_ == 1 && ref $_[0] eq 'ARRAY' ) {
        return $class->$orig({ xrefs => $_[0] });
    }

    return $class->$orig( @_ );
};

sub TO_JSON {
    my ( $self ) = @_;
    return { %$self };
}

1;
