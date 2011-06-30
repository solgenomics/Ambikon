package Ambikon::Xref;
# ABSTRACT: object representing a single Ambikon xref
use Moose;
use namespace::autoclean;

use MooseX::Types::URI 'Uri';

=attr url

the absolute or relative URL where the full resource can be accessed,
e.g. /unigenes/search.pl?q=SGN-U12

=cut

has 'url' => (
    is  => 'ro',
    isa => Uri,
    required => 1,
    coerce => 1,
   );


=attr text

a short text description of the contents of the resource referenced,
for example "6 SGN Unigenes"

=cut

has 'text' => (
    is  => 'ro',
    isa => 'Str',
    required => 1,
   );


=attr is_empty

true if the cross reference is empty, may be used as a rendering hint

=cut

has 'is_empty' => (
    is  => 'ro',
    isa => 'Bool',
    default => 0,
   );

=attr subsite

the subsite object this cross reference points to

=cut

has 'subsite' => (
    is => 'ro',
    required => 1,
   );

=attr renderings

2-level hashref of suggested renderings, keyed first by content type,
then rendering hint

=cut

has 'renderings' => (
   is      => 'ro',
   isa     => 'HashRef',
   default => sub { +{} },
 );

sub TO_JSON {
    my ( $self ) = @_;
    no strict 'refs';
    return {
        map { $_ => $self->$_() }
        qw( url is_empty text renderings )
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



