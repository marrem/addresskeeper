#!/usr/bin/perl
# Sun Jul 17 15:37:08 CEST 2016
# Marc Remijn
use warnings;
use strict;

use Config::Abstract::Ini;
use FindBin qw($Bin);

use Sys::Syslog;
use LWP;

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
	
	my %hosts = $config->get_entry('hosts');

	my $updateSuccess = 1;
	foreach my $host (values %hosts) {
		my $url = $config->get_entry_setting('set', 'url');
		$url =~ s/\$\{host\}/$host/;
		$url =~ s/\$\{ip\}/$address/;
		syslog('debug', 'Updating host [%s] -  address [%s]', ($host, $address));
		unless(updateAddress($url)) {
			$updateSuccess = 0;	
		}
	}
	return $updateSuccess;
}



sub updateAddress {
	my ($url) = @_;
	my $req = HTTP::Request->new(GET => $url);	
	my $resp = $userAgent->request($req);
	my $statusLine = $resp->status_line;
	
	my $body = $resp->content;

	if ($body =~ /^good\s+($ipRegexp)/) {
		# Update successful
		syslog('info', 'Address successfully updated to %s', ($1));
		return 1;
	} else {
		syslog('err', 'Error updating address: statusline: [%s]; body: [%s]', ($statusLine, $body));
		return 0;
	}

}
