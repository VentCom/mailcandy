# mailcandy
Tools to help you Install and interact with postfix and its related addons in a sweet way as a candy...

### Supported postfix addons 
- dovecot
- opendkim
- zeyple (mail encryption using pgp, disabled by default)
- spamassasin - coming soon 
- OpenDMARC - coming soon 
-  sieve - coming soon
- openDMARC - coming soon 

## Installation 

### Ubuntu 

sudo apt-get -y update <br />
sudo apt-get -y dist-upgrade <br />
sudo apt-get -y install postfix postfix-pcre opendkim opendkim-tools dovecot-core dovecot-imapd dovecot-lmtpd  <br />

git clone https://github.com/transcodium/mailcandy.git <br />
cd mailcandy <br />
chmod +x ./install <br />
./install  <br />
