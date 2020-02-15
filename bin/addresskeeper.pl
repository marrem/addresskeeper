#!/usr/bin/perl
# Marc Remijn
use warnings;
use strict;

use Config::Abstract::Ini;
use FindBin qw($Bin);

use Sys::Syslog;

use AddressKeeper::DNS;
use AddressKeeper::ChangeBatch;
use AddressKeeper::Change;
use AddressKeeper::ResourceRecordSet;
use AddressKeeper::ResourceRecord;



my $scriptName = $0;

$scriptName =~ s{.*/}{};
$scriptName =~ s{\.pl$}{};

my $config = new Config::Abstract::Ini("$Bin/../etc/$scriptName.cfg");
my $userAgent = LWP::UserAgent->new;
my $previousAddressStore = "$Bin/../var/${scriptName}.previous_address";
my $ipRegexp = '(\d{1,3}\.){3}\d{1,3}';

openlog($scriptName, '', 'local0');
eval {
	main();
};
syslog('info', "End of script; closing syslog connection");
closelog();


sub main {
	# Main business logic
	my ($currentAddress) = getCurrentAddress();
	syslog('info', 'Current ip address is %s', $currentAddress);	
	my ($previousAddress) = getPreviousAddress();

	unless(defined($previousAddress)) {
		syslog('info', 'Previous ip address not yet stored or invalid');	
		storeAsPrevious($currentAddress);
		return;
	}	

	syslog('info', 'Previous ip address is %s', $previousAddress);	

	if ($currentAddress ne $previousAddress) {
		syslog('warning', 'Current address [%s] different from previous address [%s]', ($currentAddress, $previousAddress));
		# We have been assigned a new address
		if (updateHosts($currentAddress)) {
			# Update successful	
			storeAsPrevious($currentAddress);
		} else {
			syslog('warning', 'One or more updates unsuccessful, leaving previous address unchanged');
		}
	}
	
}


sub getCurrentAddress {
	my $url = $config->get_entry_setting('check', 'url');
	syslog('debug', 'Requesting address at %s', ($url));
	my $checkReq = HTTP::Request->new(GET => $url);
	$checkReq->header("accept", "text/plain");

	my $response = $userAgent->request($checkReq);
	syslog('debug', 'Response status: %s', ($response->status_line));

	my $address = $response->content;

	unless ($address =~ /^$ipRegexp$/) {
		syslog('err', 'Current ip address received from %s: [%s] is invalid', ($url, $address));	
		die;
	}
	return $address;
}


sub getPreviousAddress {
	my $address;
	eval {$address = readPreviousAddress($previousAddressStore)};
	return undef unless (defined($address));
	unless ($address =~ /^$ipRegexp$/) {
		syslog('err', 'Previous ip address read from %s: [%s] is invalid', ($previousAddressStore, $address));	
		return undef;
	}
	return $address;
}



sub readPreviousAddress {
	my ($fileName) = @_;
	open(my $fileHandle, '<', $fileName) or die "Can't open $fileName (r)";
	
	read($fileHandle, my $address, 15);	
	chomp($address);
	close($fileHandle);
	return $address;
}


sub storeAsPrevious {
	my ($address) = @_;
	syslog('info', 'Storing address %s as previous', ($address));
	open(my $fileHandle, '>', $previousAddressStore) or die "Can't open $previousAddressStore (w)";
	print $fileHandle "$address\n";
	close($fileHandle);
}

sub updateHosts {
	my ($address) = @_;

	my $ttl = $config->get_entry_setting('dns', 'ttl');
	my %hosts = $config->get_entry('hosts');
	my $hostedZoneId = $config->get_entry_setting('aws', 'hosted_zone_id');

	my $hostKeysAsString = join(', ', keys(%hosts));

	my @changes;

	foreach my $hostKey (keys(%hosts)) {
		push(
			@changes,
			AddressKeeper::Change->new(
				Action            => 'UPSERT',
				ResourceRecordSet => AddressKeeper::ResourceRecordSet->new(
					Name            => $hosts{$hostKey},
					Type            => 'A',
					TTL             => $ttl + 0, # force to integer.
					ResourceRecords => [
						AddressKeeper::ResourceRecord->new(
							Value => $address,
						)
					]
				),
			),
		);
	}

	my $changeBatch = AddressKeeper::ChangeBatch->new('Changes' => \@changes, 'Comment' => "Changing address of $hostKeysAsString");

	my $dns = AddressKeeper::DNS->new($changeBatch, $hostedZoneId);

	my $updateSuccess = 1;

	eval {
		$dns->changeRecordSets();
	};
	if ($@) {
		$e = $@;
		syslog('warning', 'One updates unsuccessful: $e');
		$updateSuccess = 0;
	}

	return $updateSuccess;
}


