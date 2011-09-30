package Ambikon::Role::Serializable;
use Moose::Role;
use namespace::autoclean;

around 'TO_JSON' => sub {
    my $orig = shift;
    my $self = shift;

    my $j = $self->$orig( @_ );

    # add a __CLASS__ if not already present
    $j->{'__CLASS__'} ||= [ grep !/^Moose::/, $self->meta->linearized_isa ];

    return $j;
};

sub TO_JSON {
    return { %{ shift() } }
}

sub thaw {
    shift->new( @_ );
}

1;
