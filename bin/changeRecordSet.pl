#!/usr/bin/perl
use strict;
use warnings;
use lib '../lib';

use Data::Dumper;

use AddressKeeper::DNS;
use AddressKeeper::ChangeBatch;
use AddressKeeper::Change;
use AddressKeeper::ResourceRecordSet;
use AddressKeeper::ResourceRecord;

# Remijn.org
my $hostedZoneId = 'ZA0Y5VAU7SYE2';

my $changeBatch = AddressKeeper::ChangeBatch->new(
    'Changes' =>
        [
            AddressKeeper::Change->new(
                Action            => 'UPSERT',
                ResourceRecordSet => AddressKeeper::ResourceRecordSet->new(
                    Name            => 'host53.remijn.org',
                    Type            => 'A',
                    TTL             => 3600,
                    ResourceRecords => [
                        AddressKeeper::ResourceRecord->new(
                            Value => '4.3.3.4',
                        )
                    ]
                ),
            )
        ],
    'Comment' => 'Changing address of gateway22'
);


my $dns = AddressKeeper::DNS->new($changeBatch, $hostedZoneId);



my $result = eval {
    $dns->changeRecordSets();
};
if ($@) {
    my $e = $@;
    print Dumper($e);
    exit 1;
}

print 'OK';
print Dumper($result);




