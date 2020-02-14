package AddressKeeper::DNS;

use strict;
use warnings;

use AWS::CLIWrapper;
use Data::Dumper;
use JSON;
use File::Temp;




sub new {
	my $proto = shift;
	my $changeBatch = shift;
	my $hostedZoneId = shift;

	return bless {
		'changeBatch'  => $changeBatch,
		'hostedZoneId' => $hostedZoneId,
	}, proto;

}




# Remijn.org
my $hostedZoneId = 'ZA0Y5VAU7SYE2';

my %change_batch = (
	Changes => [
		{
			Action            => 'UPSERT',
			ResourceRecordSet => {
				Name            => 'host53.remijn.org.',
				Type            => 'A',
				TTL             => 3600,
				ResourceRecords => [
					{
						Value => '1.2.3.4',
					}
				],
			},
		},
	],
	Comment => 'Test upsert vanuit perl',
);

my $json = JSON->new();
my $tmpFile = File::Temp->new();
print $tmpFile $json->encode(\%change_batch);
$tmpFile->close();


my $aws = AWS::CLIWrapper->new();

my $result = $aws->route53(
	'change-resource-record-sets',
	{
		'hosted-zone-id' => $hostedZoneId,
		'change-batch'   => "file://$tmpFile",
	}
);

eval {
	if ($result) {
		print Dumper($result);
	}
	else {
		my $error = {
			'code' => $AWS::CLIWrapper::Error->{Code},
			'mesg' => $AWS::CLIWrapper::Error->{Message}
		};
		die $error;
	}
};

if ($@) {
	print Dumper $@;
}
