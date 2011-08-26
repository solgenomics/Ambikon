package Ambikon::Role::Renderable;
# ABSTRACT: role for objects that can be rendered for viewing by users, most commonly in HTML

use Moose::Role;

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

1;

