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

## Installing

### User

Create a user that will run this script. E.g. `addresskeeper`, group `addresskeeper`.


### Files

Copy contents of `bin`, `etc`, `lib` and `var` to e.g. `/usr/local`.

Change rights / modes to:

```
/usr/local/etc/addresskeeper.cfg  root:addresskeeper -rw-r-----
/usr/local/var/addresskeeper      root:addresskeeper drwxrwxr-x
```

### Crontab

Add file `addresskeeper` to `/etc/cron.d`

`/etc/cron.d/addresskeeper`

```
10,40 * * * * addresskeeper /usr/local/bin/addresskeeper.pl
```
This will run the script every 30 minutes, at 10 and 40 past the hour.

### Configuration

Edit `/usr/local/etc/addresskeeper.cfg`

#### Section hosts

Add every host (A) entry that should be kept at our current address (as reported by `[check]/url`).

```
[hosts]
my-gateway = gateway.mydomain.net
my-webserver = www.mydomain.net
```

Entries should be `<descriptive name> = <hostname>`.

#### Section aws

Make sure `hosted_zone_id` matches the host zone id of your domain. This id can be found in the AWS Route53 console.

```
[aws]
hosted_zone_id = AHH5747HLKJY
```
 
 
### AWS credentials

Add a `.aws` directory to the `addresskeeper` user's home directory.

```
addresskeeper@thirdworld:~$ ls -l .aws
total 8
-rw------- 1 addresskeeper addresskeeper  29 Feb 16 12:37 config
-rw------- 1 addresskeeper addresskeeper 116 Feb 16 12:37 credentials
```
It should contain your aws access key id and your secret access key.

```
[default]
aws_access_key_id = <your access key id>
aws_secret_access_key = <your secret access key>
```

Make sure that only the `addresskeeper` user can read this file.



## TODO

 * Use a config (ini) parser that accepts ';' in values (needed for 'user_agent' item).
 
