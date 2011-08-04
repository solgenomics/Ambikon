#!/usr/bin/env perl
use strict;

use Getopt::Long;
use Pod::Usage;
use Ambikon::ServerHandle;

GetOptions(
    'f=s' => \( my $opt_format = 'json' ),
  ) or pod2usage();

pod2usage() unless @ARGV;

die "invalid format $opt_format\n"
  unless { json => 1, dumper => 1 }->{$opt_format};


my $serv = Ambikon::ServerHandle->new( base_url => (shift @ARGV) );
my $data = $serv->search_xrefs( @ARGV );

if( $opt_format eq 'json' ) {
    require JSON::PP;
    print JSON::PP->new->pretty->encode( $data );
}
elsif( $opt_format eq 'dumper' ) {
    require Data::Dumper;
    print Data::Dumper::Dumper( $data );
}

exit;

=head1 NAME

  ambikon_xrefs - command-line fetch xrefs from an Ambikon integration server

=head1 SYNOPSIS

  ambikon_xrefs http://example.com "query 1" "query 2" ...

=head1 DESCRIPTION

Prints a structure of xrefs to standard output.

=cut
