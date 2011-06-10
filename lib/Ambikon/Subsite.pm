package Ambikon::Subsite;
# ABSTRACT: object representing an Ambikon subsite
use Moose;
use Moose::Util::TypeConstraints;
use MooseX::Types::URI 'Uri';

# tweak buildargs to put a copy of the complete config in our config
# attr
around 'BUILDARGS' => sub {
    my $orig  = shift;
    my $class = shift;

    if ( @_ == 1 ) {
        my ( $args ) = @_;
        return $class->$orig({ %$args, config => $args });
    } else {
        my %args = @_;
        return $class->$orig({ @_, config => \%args });
    }
};

=attr config

Hashref of all the configuration data for this subsite.

=cut

has 'config' => (
   is  => 'ro',
   isa => 'HashRef',
   required => 1,
  );

=attr shortname

Shortname of the subsite, with no whitespace.

Example: 'sgn', or 'gbrowse'.

=cut

has 'shortname' => (
    is => 'ro',
    isa => 'Str',
    required => 1,
  );

=attr alias

Arrayref of string aliases for the subsite.  Often used to categorize
subsites by their function.

=cut

{
  my $at = subtype 'alias_list', as 'ArrayRef[Str]';
  coerce $at,
    from 'Str',
    via { [ $_ ] };

  has 'alias' => (
     is      => 'ro',
     isa     => $at,
     traits  => ['Array'],
     default => sub { [] },
     coerce  => 1,
     handles => {
         add_alias   => 'push',
         alias_list  => 'elements',
     },
  );
}

=attr name

Optional longer name of the subsite.  Defaults to value of L</shortname>.

=cut

has 'name' => (
    is   => 'ro',
    isa  => 'Str',
    lazy_build => 1,
);
sub _build_name { shift->shortname }

=attr internal_url

L<URI> object for the base URL where Ambikon will access this subsite.

Example: http://localhost:3030/foo

=cut

has 'internal_url' => (
    is       => 'ro',
    isa      => Uri,
    coerce   => 1,
    required => 1,
);

=attr external_path

Relative path where this subsite is accessed by clients.

Example: C</gbrowse>

=cut

subtype 'AmbExternalPath'
    => as 'Str'
    => where { $_ =~ m!^/! }
    => message { "invalid external_path '$_': it must be a URL path relative to the site root, e.g. '/gbrowse'" };

has 'external_path' => (
    is       => 'ro',
    isa      => 'AmbExternalPath',
    required => 1,
);

sub TO_JSON {
    my ( $self ) = @_;

    return {
        ( map { $_ => ''.$self->$_ } qw(
            external_path
            internal_url
            name
            shortname
          )
        ),
        alias => $self->alias,
    };
}

__PACKAGE__->meta->make_immutable;
1;
