#!/usr/bin/perl
use strict;
use warnings;
use lib '../..';

use Test::More;
use AddressKeeper::Change;
use AddressKeeper::ResourceRecordSet;
use AddressKeeper::ResourceRecord;

{
    my $o = AddressKeeper::Change->new(
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
    );
    ok($o, 'Object created');
}



{
    eval {
        AddressKeeper::Change->new(
            Action            => 'TWADDLE',
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
        );
    };
    ok($@, 'Exception thrown when constructed with invalid \'Action\'');
}

{
    eval {
        AddressKeeper::Change->new(
            Action            => 'UPSERT',
            ResourceRecordSet => 'a recordSet',
        );
    };
    ok($@, 'Exception thrown when constructed with invalid \'ResourceRecordSet\'');
}


done_testing();

