#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use AddressKeeper::DNS;
use AddressKeeper::ChangeBatch;
use AddressKeeper::Change;
use AddressKeeper::ResourceRecordSet;
use AddressKeeper::ResourceRecord;



my @changes = (
    AddressKeeper::Change->new(
        Action            => 'UPSERT',
        ResourceRecordSet => AddressKeeper::ResourceRecordSet->new(
            Name            => 'host.domain.com',
            Type            => 'A',
            TTL             => 3600,
            ResourceRecords => [
                AddressKeeper::ResourceRecord->new(
                    Value => '1.2.3.4',
                )
            ]
        ),
    ),
);

my $changeBatch = AddressKeeper::ChangeBatch->new('Changes' => \@changes, 'Comment' => 'Updating address for webserver');

my $hostedZoneId = '12345678';


my $dns = AddressKeeper::DNS->new($changeBatch, $hostedZoneId);
ok($dns, 'Created DNS object');


eval {
    AddressKeeper::DNS->new(\@changes);
};
ok($@, 'Creating AddressKeeper::DNS object with wrong arguments throws exception');



done_testing();

