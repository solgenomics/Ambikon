package Ambikon::Role::Serializable;
use Moose::Role;

around 'TO_JSON' => sub {
    my $orig = shift;
    my $self = shift;
    my $j = $self->$orig( @_ );
    $j->{'__CLASS__'} = [ grep !/^Moose::/, $self->meta->linearized_isa ];
    return $j;
};

sub TO_JSON {
    return { %{ shift() } }
}

sub thaw {
    shift->new( @_ );
}

1;
