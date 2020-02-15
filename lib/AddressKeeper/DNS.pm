package AddressKeeper::DNS;

use strict;
use warnings;
use Carp qw(croak);
use Scalar::Util qw(blessed);
use AWS::CLIWrapper;
use JSON;
use File::Temp;
use AddressKeeper::ChangeBatch;



sub new {
    my $proto = shift;
    my $changeBatch = shift;
    my $hostedZoneId = shift;

    unless ($changeBatch && blessed($changeBatch) && $changeBatch->isa('AddressKeeper::ChangeBatch')) {
        croak("Invalid 'changeBatch', should be a 'AddressKeeper::ChangeBatch object");
    }
    unless ($hostedZoneId) {
        croak("HostedZoneId empty or undefined");
    }


    return bless {
        'changeBatch'  => $changeBatch,
        'hostedZoneId' => $hostedZoneId,
    }, $proto;

}

sub changeRecordSets {
    my $self = shift;
    my $json = JSON->new()->convert_blessed(1);
    my $tmpFile = File::Temp->new();
    print $tmpFile $json->encode($self->{changeBatch});
    $tmpFile->close();

    my $aws = AWS::CLIWrapper->new();

    my $result = $aws->route53(
        'change-resource-record-sets',
        {
            'hosted-zone-id' => $self->{hostedZoneId},
            'change-batch'   => "file://$tmpFile",
        }
    );

    if ($result) {
        return $result;
    }
    else {
        die "$AWS::CLIWrapper::Error->{Code}, $AWS::CLIWrapper::Error->{Message}";
    }

}


1;
