package AddressKeeper::ResourceRecordSet;
use strict;
use warnings;
use Carp qw(croak);
use Scalar::Util qw(blessed);
use AddressKeeper::ResourceRecord;


sub new {
    my $proto = shift;
    if (@_ % 2) {
        croak "Usage __PACKAGE__->new( 'Name' => \$name, 'Type' => \$type, 'TTL' => \$ttl, 'ResourceRecords => [\$resourceRecordA, \$resourceRecordB, ...] )";
    }
    my %args = @_;
    unless ($args{'Name'} && ! ref($args{'Name'})) {
        croak "'Name' argument empty or no scalar (string)";
    }
    unless ($args{'Type'} && ! ref($args{'Type'})) {
        croak "'Name' argument empty or no scalar (string)";
    }
    # Add other valid types
    unless (grep {$args{'Type'}} qw(A) ) {
        croak "Invalid Type '$args{'Type'}";
    }
    unless ($args{'TTL'} && ! ref($args{'TTL'}) && $args{'TTL'} =~ /^\d+$/) {
        croak "Invalid TTL: '$args{'TTL'}";
    }
    unless ($args{'ResourceRecords'} && ref($args{'ResourceRecords'}) eq 'ARRAY' && !grep {! blessed($_) || ! $_->isa('AddressKeeper::ResourceRecord')} @{ $args{'ResourceRecords'} }) {
        croak "ResourceRecords should be an array of ResourceRecord objects";
    }

    return bless {
        'Name' => $args{'Name'},
        'Type' => $args{'Type'},
        # Force to JSON number
        'TTL' => 0 + $args{'TTL'},
        'ResourceRecords' => $args{'ResourceRecords'},
    }, $proto;

}

sub TO_JSON {
    my $self = shift;
    return {%{$self}};
}


1;