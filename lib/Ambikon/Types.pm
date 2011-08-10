package Ambikon::Types;
# ABSTRACT: Moose type library for Ambikon code

use MooseX::Types
    -declare => [qw(
       TagList
    )];

use MooseX::Types::Moose qw/ ArrayRef Str /;

=head1 TYPES

=head2 TagList

a list of plain-text tags used for categorizing things.  Currently
used on both Xrefs and Subsites.

=cut

# a TagList is an arrayref of strings
subtype TagList, as ArrayRef[Str];
coerce TagList,
   from Str,
   via { [ $_ ] };

