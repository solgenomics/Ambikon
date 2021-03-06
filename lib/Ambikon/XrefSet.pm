package Ambikon::XrefSet;
# ABSTRACT: container of Xrefs
use Moose;

with 'Ambikon::Role::Taggable',
     'Ambikon::Role::Renderable',
     'Ambikon::Role::Serializable';

=head1 DESCRIPTION

A container holding Xrefs, which might have renderings or so forth for
this set of Xrefs.

=cut

=attr subsite

The subsite object this cross reference set originated from, if known,
and if all xrefs are from the same subsite.

=cut

has 'subsite' => (
    is  => 'rw',
    isa => 'Object',
   );

=attr xrefs

Arrayref of L<Ambikon::Xref> objects contained in this set.

=method is_empty

Convenient method to tell if the set is empty.  Returns whether this
holds no xrefs.

=method add_xref( $xref, ... )

Add one of more xrefs to this object.

=cut

has 'xrefs' => (
    is  => 'rw',
    isa => 'ArrayRef[Ambikon::Xref]',
    default => sub { [] },
    traits => ['Array'],
    handles => {
        is_empty => 'is_empty',
        add_xref => 'push',
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

__PACKAGE__->meta->make_immutable;
1;
