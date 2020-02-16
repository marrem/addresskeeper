#!/usr/bin/perl
# Marc Remijn
use warnings;
use strict;

use Config::Abstract::Ini;
use FindBin qw($Bin);

use LWP::UserAgent;
use Sys::Syslog;

use lib "$Bin/../lib/addresskeeper";

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
my $previousAddressStore = "$Bin/../var/${scriptName}/${scriptName}.previous_address";
my $ipRegexp = '(\d{1,3}\.){3}\d{1,3}';

my $syslogFacility = $config->get_entry_setting('syslog', 'facility', 'local7');

openlog($scriptName, '', $syslogFacility);
eval {
	main();
	syslog('info', "End of script; closing syslog connection");
	closelog();
	exit 0;
};
if ($@) {
	my $e = $@;
	syslog('warning', "Error executing script: $e");
	syslog('info', "End of script; closing syslog connection");
	closelog();
	exit 1;
}


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
		updateHosts($currentAddress);
		storeAsPrevious($currentAddress);
	}
	
}


sub getCurrentAddress {
	my $url = $config->get_entry_setting('check', 'url');
	# TODO: Config::Abstract::Ini doesn't allow ';' in values. For now hardcoded useragent.
	# my $userAgentHeader = $config->get_entry_setting('check', 'user_agent');
	my $userAgentHeader = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/79.0.3945.130 Safari/537.36';
	syslog('debug', 'Requesting address at %s', ($url));
	my $checkReq = HTTP::Request->new(GET => $url);
	$checkReq->header("accept", "text/plain");
	$checkReq->header("user-agent", $userAgentHeader);


	my $response = $userAgent->request($checkReq);
	syslog('debug', 'Response status: %s', ($response->status_line));

	unless ($response->status_line =~ /^200/) {
		die (sprintf('Error getting current address from %s: [%s]', $url, $response->content));
	}

	my $address = $response->content;

	unless ($address =~ /^$ipRegexp$/) {
		die (sprintf('Current ip address received from %s: [%s] is invalid', $url, $address));
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

	my $hostKeysAsString = join(', ', sort(keys(%hosts)));

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

	$dns->changeRecordSets();

}


