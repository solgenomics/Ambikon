package Ambikon::Subsite;
# ABSTRACT: object representing an Ambikon subsite
use Moose;
use Moose::Util::TypeConstraints;
use MooseX::Types::URI 'Uri';

use Storable 'dclone';

use Ambikon::Types 'TagList';

# tweak buildargs to put a copy of the complete config in our config
# attr
around 'BUILDARGS' => sub {
    my $orig  = shift;
    my $class = shift;

    if ( @_ == 1 ) {
        my ( $args ) = @_;
        return $class->$orig({ %$args, config => dclone($args) });
    } else {
        my %args = @_;
        return $class->$orig({ @_, config => dclone(\%args) });
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

=attr tags

Arrayref of string tags for the subsite.  Often used to categorize
subsites by their function.

=cut

has 'tags' => (
   is      => 'ro',
   isa     => TagList,
   traits  => ['Array'],
   default => sub { [] },
   coerce  => 1,
   handles => {
       add_tag   => 'push',
       tag_list  => 'elements',
   },
);


=attr name

Optional longer name of the subsite.  Defaults to value of L</shortname>.

=cut

has 'name' => (
    is   => 'ro',
    isa  => 'Str',
    lazy_build => 1,
);
sub _build_name { shift->shortname }

=attr description

short plaintext description of the feature, may be user-visible.  May
be used in default views for crossreferences and so forth.

=cut

has 'description' => (
    is      => 'ro',
    isa     => 'Str',
    default => '',
   );


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
            description
          )
        ),
        tags => $self->tags,
    };
}

__PACKAGE__->meta->make_immutable;
1;
