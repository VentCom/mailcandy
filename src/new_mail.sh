#!/usr/bin/env bash

# include config 

. ./config.sh


EMAIL_ADDRESS=$(whiptail --inputbox "Enter email address?" 20 60  --title "Enter Domain" 3>&1 1>&2 2>&3)

emailExitstatus=$?

if [[ $emailExitstatus != 0 || -z "$EMAIL_ADDRESS" ]]; then
    echo "EMail Address is required"
    exit;
fi

#password
PASSWORD=$(whiptail --passwordbox "Please enter password" 20 60  --title "Password" 3>&1 1>&2 2>&3)
 
passwordExitstatus=$?

if [[ $passwordExitstatus != 0 || -z "$PASSWORD" ]]; then
   whiptail --title "Password" --infobox "Password is required" 8 78
    exit;
fi


CONFIRM_PASSWORD=$(whiptail --passwordbox "Please confirm password" 20 60  --title "Confirm Password" 3>&1 1>&2 2>&3)
 
confirmPasswordExitstatus=$?

if [[ $confirmPasswordExitstatus != 0 || -z "$CONFIRM_PASSWORD" || $PASSWORD != $CONFIRM_PASSWORD ]]; then
    whiptail --title "Confrim Password" --infobox "Passwords do not match" 8 78
    exit;
fi

IFS="@" read EMAIL_USERNAME EMAIL_DOMAIN <<< "$EMAIL_ADDRESS"


#Append entry if it does not exist
echo "Adding $EMAIL_DOMAIN entry to $POSTFIX_VDOMAIN_DB"
POSTFIX_DOMAIN_ENTRY="$EMAIL_DOMAIN    #$EMAIL_DOMAIN"
grep -qF -- "$EMAIL_DOMAIN" "$POSTFIX_VDOMAIN_DB" || echo "$POSTFIX_DOMAIN_ENTRY" >> "$POSTFIX_VDOMAIN_DB"


#Append entry if it does not exist
echo "Adding $EMAIL_ADDRESS entry to $POSTFIX_VMAIL_BOXES_DB"
VMAIL_BOX_ENTRY="$EMAIL_ADDRESS     $EMAIL_DOMAIN/$EMAIL_USERNAME"
grep -qF -- "$EMAIL_ADDRESS" "$POSTFIX_VMAIL_BOXES_DB" || echo "$VMAIL_BOX_ENTRY" >> "$POSTFIX_VMAIL_BOXES_DB"



#Append entry if it does not exist
echo "Adding $EMAIL_ADDRESS entry to $POSTFIX_VALIAS_DB"
ALIAS_ENTRY="$EMAIL_ADDRESS      $EMAIL_ADDRESS"
grep -qF -- "$ALIAS_ENTRY" "$POSTFIX_VMAIL_ALIAS_DB" || echo "$ALIAS_ENTRY" >> "$POSTFIX_VMAIL_ALIAS_DB"


postmap $POSTFIX_VDOMAIN_DB
postmap $POSTFIX_VMAIL_BOXES_DB
postmap $POSTFIX_VMAIL_ALIAS_DB


PASSWORD_HASH=`doveadm pw -s "SHA512-CRYPT" -p "$PASSWORD" -u "$EMAIL_ADDRESS"`

DOVECOT_PASSWORD_ENTRY="$EMAIL_ADDRESS:$PASSWORD_HASH"

if ! grep -q "$DOVECOT_PASSWORD_ENTRY" "$DOVECOT_PASS_FILE"; then
    print_text "Adding $EMAIL_ADDRESS to dovecot auth"
    echo  $DOVECOT_PASSWORD_ENTRY >> $DOVECOT_PASS_FILE
    print_success "Email Added to dovecot auth"
fi

#adding keys for zeyple gpg encryption
#sudo -u zeyple gpg --homedir $ZEYPLE_KEYS_DIR --keyserver hkp://keys.gnupg.net --search $EMAIL_ADDRESS

print_text "Generating DKIM for domain $EMAIL_DOMAIN"
. ./dkim_add.sh