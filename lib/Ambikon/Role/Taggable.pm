package Ambikon::Role::Taggable;
# ABSTRACT: role for objects that have tag metadata, used mainly for categorization

use Moose::Role;

use Ambikon::Types 'TagList';

=attr tags

Arrayref of string tags for the object.  Can be used to provide
information for categorizing information.

=method add_tag( 'tag text' )

Add a tag to this object.

=method tag_list

Get the tags as a list.  Equivalent to C<< @{ $obj->tags } >>.

=method primary_tag

Get the first (primary) tag in the tag list.  Equivalent to
C<< $obj->tags->[0] >>.

=method find_tag('my_tag')

Find and return the first matching tag in this object's set of tags.
Matches are case insensitive.  Returns nothing if not found.

=method has_tag('my_tag')

Same as find_tag, but returns 1 or 0 instead of the actual tag.

=cut

has 'tags' => (
   is      => 'rw',
   isa     => TagList,
   traits  => ['Array'],
   default => sub { [] },
   coerce  => 1,
   handles => {
       add_tag     => 'push',
       tag_list    => 'elements',
       first_tag    => 'first',
   },
);

sub primary_tag { shift->tags->[0] }

sub find_tag {
    my ( $self, $tag ) = @_;
    return $self->first_tag( sub { lc $_ eq lc $tag } );
}

sub has_tag {
    shift->find_tag( @_ ) ? 1 : 0
}

1;
