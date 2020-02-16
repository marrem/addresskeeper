#!/usr/bin/perl
use strict;
use warnings;
use lib '../..';

use Test::More;
use AddressKeeper::ResourceRecordSet;
use AddressKeeper::ResourceRecord;

use JSON;

my $o = AddressKeeper::ResourceRecordSet->new(
    Name            => 'host.domain.com',
    Type            => 'A',
    TTL             => 3600,
    ResourceRecords => [
        AddressKeeper::ResourceRecord->new(
            Value => '1.2.3.4',
        )
    ]
);
ok($o, 'Object created');


{
    eval {
        my $o = AddressKeeper::ResourceRecordSet->new(
            Name            => 'host.domain.com',
            Type            => 'A',
            TTL             => '3600xyz',
            ResourceRecords => [
                AddressKeeper::ResourceRecord->new(
                    Value => '1.2.3.4',
                )
            ]
        );
    };
    ok($@, 'Exception thrown when constructed with invalid \'TTL\'');
}



{
    eval {
        my $o = AddressKeeper::ResourceRecordSet->new(
            Name            => 'host.domain.com',
            Type            => 'A',
            TTL             => 3600,
            ResourceRecords => [
                '1.2.3.4',
            ]
        );
    };
    ok($@, 'Exception thrown when constructed with invalid \'ResourceRecords\'');
}

my $json_encoder = JSON->new()->convert_blessed(1);

my $json = $json_encoder->encode($o);

note $json;

ok($json && !ref($json), 'JSON representation');


done_testing();

