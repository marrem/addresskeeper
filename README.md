# addresskeeper
Perl script that updates aws route53 dns records with current public ip address.

To find out current ip address it uses a bot that returns current ip address on http get.
At the moment it uses:  http://bot.whatismyipaddress.com. It's configurable, but the api should
return a body only containing the ip address.

To change dns it uses AWS-CLI's route53 API.

## dependencies

### Perl modules
* LWP
* Config::Abstract::Ini
* AWS::CLIWrapper
* FindBin (core)
* Sys::Syslog (core)

### Non perl

* aws cli


