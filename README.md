# addresskeeper
Perl script that updates dns with current public ip address

I created this to update my dns at Dutch service provider [bHosted](http://www.bhosted.nl). 
They use a nonstandard web service call (a simple GET) that I couldn't get working correctly using some of the well known dynamic dns packages available to me at the debian/ubuntu package repositories.

## dependencies

### Perl modules
* Config::Abstract::Ini
* AWS::CLIWrapper
* FindBin (core)
* Sys::Syslog (core)

### Non perl

* aws cli


