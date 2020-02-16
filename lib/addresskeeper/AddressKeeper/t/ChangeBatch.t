#!/usr/bin/perl
use strict;
use warnings;
use lib '../..';

use Test::More;
use AddressKeeper::ChangeBatch;
use AddressKeeper::Change;
use AddressKeeper::ResourceRecordSet;
use AddressKeeper::ResourceRecord;

use JSON;

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

my $o = AddressKeeper::ChangeBatch->new('Changes' => \@changes, 'Comment' => 'Changing address of gateway22');
ok($o, 'Object created');



{
    eval {
        AddressKeeper::ChangeBatch->new('Changes' => [ 'something' ], 'Comment' => 'Changing address of gateway22');
    };
    ok($@, 'Exception thrown when constructed with invalid \'Changes\'');
}

{
    eval {
        AddressKeeper::ChangeBatch->new('Changes' => \@changes, 'Comment' => 'Changing address of gateway22');
    };
    ok(!$@, 'Constructing without \'Comment\' (optional) is accepted');
}

my $json_encoder = JSON->new()->convert_blessed(1);

my $json = $json_encoder->encode($o);

warn $json;

ok($json && !ref($json), 'JSON representation');


done_testing();

