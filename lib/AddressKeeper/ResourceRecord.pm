package AddressKeeper::ResourceRecord;
use strict;
use warnings;
use Carp qw(croak);



sub new {
    my $proto = shift;
    if (@_ % 2) {
        croak "Usage __PACKAGE__->new( 'Value' => \$value)";
    }
    my %args = @_;
    unless ($args{'Value'} && ! ref($args{'Value'})) {
        croak "'Value' argument empty or no scalar (string)";
    }

    return bless {
        'Value' => $args{'Value'},
    }, $proto;

}


sub TO_JSON {
    my $self = shift;
    return {%{ $self }};
}

1;