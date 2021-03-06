package Ambikon::Xref;
# ABSTRACT: object representing a single Ambikon xref
use Moose;
use Moose::Util::TypeConstraints;
use namespace::autoclean;

use MooseX::Types::URI 'Uri';

with 'Ambikon::Role::Taggable',
     'Ambikon::Role::Renderable',
     'Ambikon::Role::Serializable';

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
        ( $a->subsite && $b->subsite && $a->subsite->name cmp $b->subsite->name )
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
        && $a->_subsite_name eq $b->_subsite_name;
}

sub uniq {
    my %seen;
    grep !$seen{ _uniq_str($_) }++, @_;
}
sub _uniq_str {
    my ( $self ) = @_;
    return join ',', (
        $self->_subsite_name,
        $self->url,
        $self->text,
       );
}

sub _subsite_name {
    my $self = shift;
    my $s = $self->subsite;
    return '(unknown subsite)' unless $s;
    return $s->name;
}

{ no warnings 'once';
  *distinct = \&uniq;
}

__PACKAGE__->meta->make_immutable;
1;



