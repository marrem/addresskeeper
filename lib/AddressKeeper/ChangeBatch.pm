package AddressKeeper::ChangeBatch;
use strict;
use warnings;
use Carp qw(croak);
use Scalar::Util qw(blessed);
use AddressKeeper::Change;


sub new {
    my $proto = shift;
    if (@_ % 2) {
        croak "Usage __PACKAGE__->new( 'Changes' => \$changes, 'Comment' => \$comment, ... )";
    }
    my %args = @_;
    unless ($args{'Changes'} && ref($args{'Changes'}) eq 'ARRAY' && !grep {! blessed($_) || ! $_->isa('AddressKeeper::Change')} @{ $args{'Changes'} }) {
        croak "Changes should be an array of Change objects";
    }
    # Comment is optional (?)
    return bless {
        'Changes' => $args{'Changes'},
        'Comment' => $args{'Comment'},
    }, $proto;

}



1;