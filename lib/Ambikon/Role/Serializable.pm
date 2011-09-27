package Ambikon::Role::Serializable;
use Moose::Role;

around 'TO_JSON' => sub {
    my $orig = shift;
    my $self = shift;
    my $j = $self->$orig( @_ );
    $j->{'__CLASS__'} = ref $self;
    return $j;
};

sub TO_JSON {
    return { %{ shift() } }
}

1;
