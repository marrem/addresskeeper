use strict;
# use warnings;


use Paws;
use Data::Dumper;


# Remijn.org
my $hostedZoneId = 'ZA0Y5VAU7SYE2';

my $route53service = Paws->service('Route53');






my $result = $route53service->ChangeResourceRecordSets(
	ChangeBatch => {
		Changes => [
			{
				Action => 'UPSERT',
				ResourceRecordSet => {
					Name => 'host53.remijn.org.',
					Type => 'A',
					TTL => 3600,
					ResourceRecords => [
						{
							Value => '1.2.3.4',
						}
					],	
				},
			},
		],
		Comment => 'Test upsert vanuit perl',		
	},
	HostedZoneId => $hostedZoneId,
);


print Dumper($result);
