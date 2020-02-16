#!/usr/bin/perl
use strict;
use warnings;
use lib '../..';

use Test::More;
use AddressKeeper::ResourceRecord;

use JSON;

my $o = AddressKeeper::ResourceRecord->new(
    Value => '1.2.3.4'
);
ok($o, 'Object created');



{
    eval {
        my $o = AddressKeeper::ResourceRecord->new();
    };
    ok($@, 'Exception thrown when constructed with absent \'Value\'');
}

my $json_encoder = JSON->new()->convert_blessed(1);

my $json =  $json_encoder->encode($o);

ok($json && !ref($json), 'JSON representation');

done_testing();

