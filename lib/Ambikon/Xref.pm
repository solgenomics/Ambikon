package Ambikon::Xref;
# ABSTRACT: object representing a single Ambikon xref
use Moose;
use Moose::Util::TypeConstraints;
use namespace::autoclean;

use MooseX::Types::URI 'Uri';

use Ambikon::Types 'TagList';

=attr url

the absolute or relative URL where the full resource can be accessed,
e.g. /unigenes/search.pl?q=SGN-U12

=cut

has 'url' => (
    is  => 'rw',
    isa => Uri,
    required => 1,
    coerce => 1,
   );


=attr text

a short text description of the contents of the resource referenced,
for example "6 SGN Unigenes"

=cut

has 'text' => (
    is  => 'rw',
    isa => 'Str',
    required => 1,
   );

=attr tags

Arrayref of string tags for the xref.  Can be used to provide
information for categorizing xrefs.

=cut


has 'tags' => (
   is      => 'rw',
   isa     => TagList,
   traits  => ['Array'],
   default => sub { [] },
   coerce  => 1,
   handles => {
       add_tag   => 'push',
       tag_list  => 'elements',
   },
);

=attr is_empty

true if the cross reference is empty, may be used as a rendering hint

=cut

has 'is_empty' => (
    is  => 'rw',
    isa => 'Bool',
    default => 0,
   );

=attr subsite

The subsite object this cross reference points to, if known.  Subsites
that are creating xrefs do not have to populate this.

=cut

has 'subsite' => (
    is  => 'rw',
    isa => 'Object',
   );

=attr renderings

2-level hashref of suggested renderings, keyed first by content type,
then rendering hint

=cut

has 'renderings' => (
   is      => 'rw',
   isa     => 'HashRef',
   default => sub { +{} },
 );

sub TO_JSON {
    my ( $self ) = @_;
    no strict 'refs';
    return {
        url => ''.$self->url,
        map { $_ => $self->$_() }
        qw( is_empty text renderings tags)
    };
}

sub xref_cmp {
    my ( $a, $b ) = @_;
    no warnings 'uninitialized';
    return
        $a->subsite->name cmp $b->subsite->name
     || $a->is_empty <=> $b->is_empty
     || $a->text cmp $b->text
     || $a->url.'' cmp $b->url.'';
}

sub xref_eq {
    my ( $a, $b ) = @_;

    no warnings 'uninitialized';
    return !($a->is_empty xor $b->is_empty)
        && $a->text eq $b->text
        && $a->url.'' eq $b->url.''
        && $a->subsite->name eq $b->subsite->name;
}

sub uniq {
    my %seen;
    grep !$seen{ _uniq_str($_) }++, @_;
}
sub _uniq_str {
    my ( $self ) = @_;
    return join ',', (
        $self->subsite->name,
        $self->url,
        $self->text,
       );
}

{ no warnings 'once';
  *distinct = \&uniq;
}


1;



