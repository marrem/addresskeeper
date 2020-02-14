package AddressKeeper::Change;
use strict;
use warnings;
use Carp qw (croak confess);
use Scalar::Util qw(blessed);
use AddressKeeper::ResourceRecordSet;

sub new {
    my $proto = shift;
    if (@_ % 2) {
        croak "Usage __PACKAGE__->new( 'Action' => \$action, 'ResourceRecordSet => \$resourceRecordSet )";
    }
    my %args = @_;

    unless ($args{'Action'} && !ref($args{'Action'})) {
        confess ("'Action' argument empty or not a scalar (string)");
    }
    # At the moment we only support UPSERT action
    unless (grep {$_ eq $args{'Action'}} qw(UPSERT) ) {
        croak ("Invalid Action '$args{'Action'}");
    }
    unless ($args{'ResourceRecordSet'} && blessed($args{'ResourceRecordSet'}) && $args{'ResourceRecordSet'}->isa('AddressKeeper::ResourceRecordSet')) {
        croak "Argument 'ResourceRecordSet should be an object of type 'AddressKeeper::ResourceRecordSet'";
    }

    return bless {
        'Action' => $args{'Action'},
        'ResourceRecordSet' => $args{'ResourceRecordSet'},
    }, $proto;

}



sub TO_JSON {
    my $self = shift;
    return {%{ $self }};
}


1;