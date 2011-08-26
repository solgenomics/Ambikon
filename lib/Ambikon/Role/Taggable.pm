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
   },
);

sub primary_tag { shift->tags->[0] }

1;
