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

# include config 
. ./config.sh

#Server  Hostname or IP
SYSTEM_HOSTNAME=`hostname -f`


HOSTNAME=$(whiptail --inputbox "Enter The domain part of the email?" 20 60 "$SYSTEM_HOSTNAME" --title "Enter Domain" 3>&1 1>&2 2>&3)

hostnameExitstatus=$?

if [[ $hostnameExitstatus != 0 || -z "$HOSTNAME" ]]; then
    print_error "Hostname is required"
    exit;
fi


POSTFIX_CONFIG_DIR=/etc/postfix
DOVECOT_CONFIG_DIR=/etc/dovecot
CURRENT_DIR=`dirname $0`


declare -A MAIN_CONFIG
MAIN_CONFIG=(

    [HOSTNAME]=$HOSTNAME
    
    #PostFix
    [POSTFIX_VMAIL_BASE]=$POSTFIX_VMAIL_BASE
    [POSTFIX_CONFIG_DIR]=$POSTFIX_CONFIG_DIR
    
    [POSTFIX_MAIN_CONFIG]=$POSTFIX_MAIN_CONFIG
    [POSTFIX_MASTER_CONFIG]=$POSTFIX_MASTER_CONFIG
   
    [POSTFIX_VDOMAIN_DB]=$POSTFIX_VDOMAIN_DB
    [POSTFIX_VMAIL_ALIAS_DB]=$POSTFIX_VMAIL_ALIAS_DB
    [POSTFIX_VMAIL_BOXES_DB]=$POSTFIX_VMAIL_BOXES_DB
  
    [POSTFIX_MAIN_CONFIG]=$POSTFIX_MAIN_CONFIG
    [POSTFIX_MASTER_CONFIG]=$POSTFIX_MASTER_CONFIG
    
    [POSTFIX_VMAIL_USER]=$POSTFIX_VMAIL_USER
    [POSTFIX_VMAIL_GROUP]=$POSTFIX_VMAIL_GROUP

    [POSTFIX_VMAIL_UID]=$POSTFIX_VMAIL_UID
    [POSTFIX_VMAIL_GID]=$POSTFIX_VMAIL_GID

    #Dovecot
    [DOVECOT_CONFIG_DIR]=$DOVECOT_CONFIG_DIR
    [DOVECOT_CONFIG_FILE]=$DOVECOT_CONFIG_FILE

    #opendkim
    [OPEN_DKIM_CONFIG]=$OPEN_DKIM_CONFIG
    [OPEN_DKIM_DIR]=$OPEN_DKIM_DIR
   
    [DKIM_KEYS_DIR]=$DKIM_KEYS_DIR
    [DKIM_KEY_TABLE]=$DKIM_KEY_TABLE
   
    [DKIM_TRUSTED_HOSTS_FILE]=$DKIM_TRUSTED_HOSTS_FILE
    [DKIM_SIGNING_TABLE]=$DKIM_SIGNING_TABLE
   
    [DKIM_USER]=$DKIM_USER
    [DKIM_SELECTOR]=$DKIM_SELECTOR

    [OPENDKIM_SOCKET]=$OPENDKIM_SOCKET
)

print_text "Setting /etc/postfix ownership to postfix:root"
chown postfix:postfix /etc/postfix

POSTFIX_FILES="/etc/postfix/postfix-files"

if ! [ -e $POSTFIX_FILES ]; then 
    touch $POSTFIX_FILES
    chown postfix:postfix $POSTFIX_FILES
fi

#Check if group exists
if [ $(getent group $POSTFIX_VMAIL_GROUP) ]; then
  
  POSTFIX_VMAIL_GID="$(getent group $POSTFIX_VMAIL_GROUP | cut -d: -f3)"

  print_text "Group $POSTFIX_VMAIL_GROUP exists already, using GID : $POSTFIX_VMAIL_GID"


  MAIN_CONFIG["POSTFIX_VMAIL_GID"]=$POSTFIX_VMAIL_GID

else
      print_text "Group $POSTFIX_VMAIL_GID does not exists, adding group"  
      groupadd -g $POSTFIX_VMAIL_GID $POSTFIX_VMAIL_GROUP

fi

# Craete vmail user if account doesnt exists
if [ `id -u  $POSTFIX_VMAIL_USER 2>/dev/null || echo -1` -ge 0 ]; then 

    POSTFIX_VMAIL_UID=`id -u $POSTFIX_VMAIL_USER`
    print_text "User $POSTFIX_VMAIL_USER already exists, using uid: $POSTFIX_VMAIL_UID"

   MAIN_CONFIG["POSTFIX_VMAIL_UID"]=$POSTFIX_VMAIL_UID

else

    print_text "User $POSTFIX_VMAIL_USER not found, adding one"

    mkdir -p $POSTFIX_VMAIL_BASE

    useradd -r -g $POSTFIX_VMAIL_GROUP -u $POSTFIX_VMAIL_UID "$POSTFIX_VMAIL_USER" -d $POSTFIX_VMAIL_BASE -c "virtual mail user"

    chown -R $POSTFIX_VMAIL_USER:dovecot $DOVECOT_CONFIG_DIR
   
fi

chown -R $POSTFIX_VMAIL_USER:$POSTFIX_VMAIL_GROUP $POSTFIX_VMAIL_BASE


### Fun 
function process_config_placeholder(){

    local TEMPLATE_FILE=$1
    local PROCCESSED_TEMPLATE_FILE=$2

    if [ -e $PROCCESSED_TEMPLATE_FILE ]; then
        unlink $PROCCESSED_TEMPLATE_FILE
    fi

    #Strange sed was sending unedited text data to processed file, so we do inline editing which seems to work
    cp $TEMPLATE_FILE $PROCCESSED_TEMPLATE_FILE

   for i in "${!MAIN_CONFIG[@]}"
    do
        search="%($i)%"
        replace=${MAIN_CONFIG[$i]}
        # Note the "" after -i, needed in OS X
        sed -in.bak "s|${search}|${replace}|g" $PROCCESSED_TEMPLATE_FILE 
    done

} #end function 


#backup the old one 
timestamp=$( date '+%Y-%m-%d-%H-%M-%S' )

#postfix config
TEMPLATE_FILE_DIR=$CURRENT_DIR/conf

declare -a CONFIG_FILES_ARRAY

CONFIG_FILES_ARRAY=(postfix  dovecot opendkim)


for config_name in "${CONFIG_FILES_ARRAY[@]}"
do 
     CONFIG_TEMPLATE="$TEMPLATE_FILE_DIR/$config_name.conf"

     PROCESSED_CONFIG_TEMPLATE="$TEMPLATE_FILE_DIR/$config_name.processed.conf"

    process_config_placeholder "$CONFIG_TEMPLATE" "$PROCESSED_CONFIG_TEMPLATE"

    declare CONFIG_TO_REPLACE_PATH

    if [ "$config_name" = "postfix" ]; then 
        CONFIG_TO_REPLACE_PATH=$POSTFIX_MAIN_CONFIG
    elif [ "$config_name" = "dovecot" ]; then     
         CONFIG_TO_REPLACE_PATH=$DOVECOT_CONFIG_FILE
    elif [ "$config_name" = "opendkim" ]; then 
         CONFIG_TO_REPLACE_PATH=$OPEN_DKIM_CONFIG     
    else  
        print_error "Unknown config name $config_name"
        continue
    fi    

    #backup configuration to replace
    BACKUP_FILE_PATH="$CONFIG_TO_REPLACE_PATH.orig.$timestamp"
    
    print_text "Backing up config file $CONFIG_TO_REPLACE_PATH --> $BACKUP_FILE_PATH"
    mv $CONFIG_TO_REPLACE_PATH $BACKUP_FILE_PATH
    
    print_success "Backup done --> $BACKUP_FILE_PATH"

    print_text "Replacing config file --> $CONFIG_TO_REPLACE_PATH"

    mv $PROCESSED_CONFIG_TEMPLATE $CONFIG_TO_REPLACE_PATH 
done 


#Process Postmap extra config
if ! [ -e "$POSTFIX_VDOMAIN_DB" ]; then 
    print_text "Creating file -->   $POSTFIX_VDOMAIN_DB"
    touch  $POSTFIX_VDOMAIN_DB
    chown -R postfix:postfix  $POSTFIX_VDOMAIN_DB
fi    

if ! [ -e "$POSTFIX_VMAIL_BOXES_DB" ]; then 
    print_text "Creating file -->   $POSTFIX_VMAIL_BOXES_DB"
    touch $POSTFIX_VMAIL_BOXES_DB
    chown -R postfix:postfix  $POSTFIX_VMAIL_BOXES_DB
fi    

if ! [ -e "$POSTFIX_VMAIL_ALIAS_DB" ]; then 
    print_text "Creating file -->   $POSTFIX_VMAIL_ALIAS_DB"
    touch $POSTFIX_VMAIL_ALIAS_DB
    chown  postfix:postfix  $POSTFIX_VMAIL_ALIAS_DB
fi


sudo postmap $POSTFIX_VDOMAIN_DB
sudo postmap $POSTFIX_VMAIL_BOXES_DB
sudo postmap $POSTFIX_VMAIL_ALIAS_DB

##Add postfix network entry, chek missing or commented
INET_PATTERN="[#]*[ ]*submission[ ]*inet[ ]*n[ ]*-[ ]*n[ ]*-[ ]*-[ ]*smtpd"
if ! grep -q "$INET_PATTERN" "$POSTFIX_MASTER_CONFIG"; then

   print_text "adding submission inet in $POSTFIX_MASTER_CONFIG" 
   echo " " >>  $POSTFIX_MASTER_CONFIG
   echo "submission inet n       -       n       -       -       smtpd" >> $POSTFIX_MASTER_CONFIG

fi 


POSTFIX_HEADER_CHECK_FILE="$POSTFIX_CONFIG_DIR/header_checks"
POSTFIX_HEADER_CHECK_TEMPLATE_FILE="$TEMPLATE_FILE_DIR/header_checks"

#if header_checks is not in etc
if ! [ -e $POSTFIX_HEADER_CHECK_FILE ]; then 
    cp $POSTFIX_HEADER_CHECK_TEMPLATE_FILE $POSTFIX_HEADER_CHECK_FILE
fi

#check if header check file has been added to the postfix master conf
if ! grep -q "$POSTFIX_HEADER_CHECK_FILE" "$POSTFIX_MASTER_CONFIG"; then

print_text "Writing header_check to -> $POSTFIX_MASTER_CONFIG"

 echo " " >>  $POSTFIX_MASTER_CONFIG

cat >>  "$POSTFIX_MASTER_CONFIG" <<EOF
cleanup   unix  n       -       n       -       0       cleanup
  -o header_checks=pcre:$POSTFIX_HEADER_CHECK_FILE
EOF

fi  #end if

#Dovecot Lmtp listener file
DOVECOT_AUTH_SOCKET=/var/spool/postfix/private/auth

if [ -d "$DOVECOT_AUTH_SOCKET" ]; then 
    mkdir $DOVECOT_AUTH_SOCKET
    chown -R postfix:postfix $DOVECOT_AUTH_SOCKET
    chmod 666 $DOVECOT_AUTH_SOCKET
fi


# Open DKIM 
if ! [ -d $OPEN_DKIM_DIR ]; then

    print_text "Creating open dkim folder structures and files" ..

    mkdir -p $OPEN_DKIM_DIR
   
    touch $DKIM_KEY_TABLE
    touch $DKIM_SIGNING_TABLE
    touch $DKIM_TRUSTED_HOSTS_FILE

    echo "localhost" >> $DKIM_TRUSTED_HOSTS_FILE
    echo "127.0.0.1" >> $DKIM_TRUSTED_HOSTS_FILE


    chown -R $DKIM_USER:$DKIM_USER  $OPEN_DKIM_DIR
    
    print_success "open dkim folder structure and files created successfully .."
fi 


#Add postfix to opendkim group
sudo usermod -a -G opendkim postfix


#fix opendkim socket bug 
#Craete Open dkim socket path in such a way that postfix can have an acess to it
if ! [ -d $OPENDKIM_SOCKET_DIR ]; then 
    sudo mkdir -p $OPENDKIM_SOCKET_DIR
    sudo chown opendkim:opendkim $OPENDKIM_SOCKET_DIR
fi

# Edit the default config 
#/etc/default/opendkim
OPENDKIM_DEFUALT_CONFIG="/etc/default/opendkim"
OPENDKIM_DEFAULT_SOCKET_ENTRY="SOCKET=$OPENDKIM_SOCKET"

if ! grep -q "$OPENDKIM_DEFAULT_SOCKET_ENTRY" "$OPENDKIM_DEFUALT_CONFIG"; then

    print_text "Editing opendkim default config -> $OPENDKIM_DEFUALT_CONFIG"
    print_text "adding $OPENDKIM_DEFAULT_SOCKET_ENTRY -> $OPENDKIM_DEFUALT_CONFIG"

    #replace exisiting line 
    sed -i '/^SOCKET[ ]*=[ ]*/s/^/#/' $OPENDKIM_DEFUALT_CONFIG

    echo $OPENDKIM_DEFAULT_SOCKET_ENTRY >> $OPENDKIM_DEFUALT_CONFIG
fi 



#dovecot generate cert
bash ./mkcert.sh

#. ./install_zeyple.sh

service postfix restart
service dovecot restart
service opendkim restart



