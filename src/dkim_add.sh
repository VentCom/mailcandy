# Copyright 2018 - Transcodium Ltd.
#  All rights reserved. This program and the accompanying materials
#  are made available under the terms of the  Apache License v2.0 which accompanies this distribution.
#
#  The Apache License v2.0 is available at
#  http://www.opensource.org/licenses/apache2.0.php
#
#  You are required to redistribute this code under the same licenses.
#
#  Project TNSMoney
#  @author Razak Zakari <razak@transcodium.com>
#  https://transcodium.com

#!/usr/bin/env bash

DOMAIN=$EMAIL_DOMAIN

if [ -z $DOMAIN ]; then
  print_error "Domain is required"
  exit;
fi



DOMAIN_KEY_PATH=$DKIM_KEYS_DIR/$DOMAIN

mkdir -p  $DOMAIN_KEY_PATH

opendkim-genkey -s $DKIM_SELECTOR -d  $DOMAIN -D $DOMAIN_KEY_PATH

chown -R  $DKIM_USER:$DKIM_USER  $DOMAIN_KEY_PATH


if ! [ -e $DKIM_KEY_TABLE ]; then
  echo "Creating KeyTable File -> $DKIM_KEY_TABLE"
  touch  $DKIM_KEY_TABLE 
  chown $DKIM_USER:$DKIM_USER  $DKIM_KEY_TABLE
fi

#APPEND TO SignTable 
SIGNING_TABLE_ENTRY="*@$DOMAIN $DKIM_SELECTOR._domainkey.$DOMAIN"

#Append entry if it does not exist
echo "Adding $DOMAIN entry to $DKIM_SIGNING_TABLE"
grep -qF -- "$SIGNING_TABLE_ENTRY" "$DKIM_SIGNING_TABLE" || echo "$SIGNING_TABLE_ENTRY" >> "$DKIM_SIGNING_TABLE"


KEYTABLE_ENTRY="$DKIM_SELECTOR._domainkey.$DOMAIN $DOMAIN:$DKIM_SELECTOR:$DOMAIN_KEY_PATH/mail.private"

# Append DB key entry into file
echo "Adding $DOMAIN entry to $DKIM_KEY_TABLE"
grep -qF -- "$KEYTABLE_ENTRY" "$DKIM_KEY_TABLE" || echo "$KEYTABLE_ENTRY" >> "$DKIM_KEY_TABLE"


if ! [ -e $DKIM_TRUSTED_HOSTS_FILE ]; then
 
  echo "Creating File -> $DKIM_TRUSTED_HOSTS_FILE"
  
  touch  $DKIM_TRUSTED_HOSTS_FILE 
  
  chown  $DKIM_USER:$DKIM_USER  $DKIM_TRUSTED_HOSTS_FILE

  #add local hosts 
  echo "127.0.0.1" >>  $DKIM_TRUSTED_HOSTS_FILE
  echo "localhost" >>  $DKIM_TRUSTED_HOSTS_FILE

fi

#add trusted host for our domain
print_text "Adding $DOMAIN entry to $DKIM_TRUSTED_HOSTS_FILE"
grep -qF -- "$DOMAIN" "$DKIM_TRUSTED_HOSTS_FILE" || echo "$DOMAIN" >> "$DKIM_TRUSTED_HOSTS_FILE"


DKIM_DNS_ENTRY_FILE="$DOMAIN_KEY_PATH/mail.txt"

DKIM_DNS_DATA=`cat $DKIM_DNS_ENTRY_FILE`

#whiptail --title "ADD TO  DOMAIN'S DNS" --msgbox '$DKIM_DNS_DATA' 8 78

echo ""
echo "ADD THIS to $DOMAIN DNS RECORD"
echo 'Note: Copy and Join the keys from "p=..."; "..." till end after the " quotes'
echo ""
echo $DKIM_DNS_DATA 
echo ""

print_text "Restarting opendkim"
service opendkim restart

#KeyTable                refile:/etc/opendkim/KeyTable
#SigningTable            refile:/etc/opendkim/SigningTable
#ExternalIgnoreList      refile:/etc/opendkim/TrustedHosts
#InternalHosts           refile:/etc/opendkim/TrustedHosts