#!/usr/bin/env bash

POSTFIX_CONFIG_DIR=/etc/postfix
POSTFIX_MAIN_CONFIG=$POSTFIX_CONFIG_DIR/main.cf

POSTFIX_MASTER_CONFIG=$POSTFIX_CONFIG_DIR/master.cf
POSTFIX_VMAIL_BOXES_DB=$POSTFIX_CONFIG_DIR/vmail_mailboxes

POSTFIX_VDOMAIN_DB=$POSTFIX_CONFIG_DIR/vmail_domains
POSTFIX_VMAIL_ALIAS_DB=$POSTFIX_CONFIG_DIR/vmail_alias

POSTFIX_VMAIL_BASE=/var/mail/vhosts

POSTFIX_VMAIL_USER=vmail
POSTFIX_VMAIL_GROUP=vmail

POSTFIX_VMAIL_UID=5000
POSTFIX_VMAIL_GID=5000


#Dovecot
DOVECOT_CONFIG_DIR=/etc/dovecot
DOVECOT_CONFIG_FILE=$DOVECOT_CONFIG_DIR/dovecot.conf
DOVECOT_PASS_FILE=/etc/dovecot/passwd

#Open Dkim
OPEN_DKIM_CONFIG=/etc/opendkim.conf
OPEN_DKIM_DIR=/etc/opendkim
DKIM_KEYS_DIR=$OPEN_DKIM_DIR/keys
DKIM_KEY_TABLE=$OPEN_DKIM_DIR/KeyTable
DKIM_TRUSTED_HOSTS_FILE=$OPEN_DKIM_DIR/TrustedHosts
DKIM_SIGNING_TABLE=$OPEN_DKIM_DIR/SigningTable
DKIM_USER="opendkim"
DKIM_SELECTOR="mail"
OPENDKIM_SOCKET_DIR="/var/spool/postfix/var/run/opendkim"
OPENDKIM_SOCKET="$OPENDKIM_SOCKET_DIR/opendkim.sock"


#ZEYPLE
ZEYPLE_KEYS_DIR=/var/lib/zeyple/keys

#### basic functions ###

function print_text(){
    echo -e "\e[87m${1}\e[0m"
}

function print_success(){
    echo -e "\e[32m${1}\e[0m"
}

function print_error(){
    echo -e "\e[31m${1}\e[0m"
}

