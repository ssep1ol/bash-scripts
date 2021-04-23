#!/bin/bash
# Thanks to @ank0m
EXEC_DATE=`date +%Y-%m-%d`
SPAMHAUS_DROP="/usr/local/src/drop.txt"
SPAMHAUS_eDROP="/usr/local/src/edrop.txt"
URL="https://www.spamhaus.org/drop/drop.txt"
eURL="https://www.spamhaus.org/drop/edrop.txt"
DROP_ADD_TO_UFW="/usr/local/src/DROP2.txt"
eDROP_ADD_TO_UFW="/usr/local/src/eDROP2.txt"
DROP_ARCHIVE_FILE="/usr/local/src/DROP_$EXEC_DATE"
eDROP_ARCHIVE_FILE="/usr/local/src/eDROP_$EXEC_DATE"
# All credits for the following BLACKLISTS goes to "The Spamhaus Project" - https://www.spamhaus.org
#####
## To remove or revert these rules, keep the list of IPs!
## Run a command like so to remove the rules:
 while read line; do ufw delete deny from $line; done < $DROP_ARCHIVE_FILE
 while read line; do ufw delete deny from $line; done < $eDROP_ARCHIVE_FILE

#####
