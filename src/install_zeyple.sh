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

APP_NAME="zeyple"


print_text "Adding user zeyple"
adduser --system --no-create-home --disabled-login $APP_NAME

SRC_DIR=/usr/src

APP_SRC_DIR="$SRC_DIR/zeyple"

if [ -e "$APP_SRC_DIR" ]; then 
    rm -rf "$APP_SRC_DIR"
fi

cd $SRC_DIR && sudo git clone https://github.com/infertux/$APP_NAME.git

mkdir -p $ZEYPLE_KEYS_DIR
chmod 700 $ZEYPLE_KEYS_DIR
chown zeyple: $ZEYPLE_KEYS_DIR

cp  "$APP_SRC_DIR/zeyple/zeyple.conf.example" /etc/zeyple.conf

cp  "$APP_SRC_DIR/zeyple/zeyple.py" /usr/local/bin/zeyple.py

chmod 744 /usr/local/bin/zeyple.py 
chown zeyple: /usr/local/bin/zeyple.py

touch /var/log/zeyple.log && chown zeyple: /var/log/zeyple.log

##Add postfix network entry, chek missing or commented
ZEYPLE_PATTERN="user=zeyple[ ]*argv=/usr/local/bin/zeyple.py"
if ! grep -q "$ZEYPLE_PATTERN" "$POSTFIX_MASTER_CONFIG"; then

print_text "adding zeyple config to $POSTFIX_MASTER_CONFIG" 
echo " " >>  $POSTFIX_MASTER_CONFIG
   
#Heredoc, dont put any spaces   
cat >>  "$POSTFIX_MASTER_CONFIG" <<'CONF'
zeyple    unix  -       n       n       -       -       pipe
  user=zeyple argv=/usr/local/bin/zeyple.py ${recipient}

localhost:10026 inet  n       -       n       -       10      smtpd
  -o content_filter=
  -o receive_override_options=no_unknown_recipient_checks,no_header_body_checks,no_milters
  -o smtpd_helo_restrictions=
  -o smtpd_client_restrictions=
  -o smtpd_sender_restrictions=
  -o smtpd_recipient_restrictions=permit_mynetworks,reject
  -o mynetworks=127.0.0.0/8,[::1]/128
  -o smtpd_authorized_xforward_hosts=127.0.0.0/8,[::1]/128
CONF
fi 