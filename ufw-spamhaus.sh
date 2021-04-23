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
echo "Start time: $(date)"
echo " "
echo "Download daily DROP file:"
wget -q -O - "$URL" > $SPAMHAUS_DROP
grep -v '^;' $SPAMHAUS_DROP | cut -d ' ' -f 1 > $DROP_ADD_TO_UFW
echo " "
echo "Extract DROP IP addresses and add to UFW:"
cat $DROP_ADD_TO_UFW | while read line
do
/usr/sbin/ufw insert 1 deny from "$line" comment 'DROP_Blacklisted_IPs'
done
echo " "
echo "Downloading eDROP list and import to UFW"
echo " "
echo "Download daily eDROP file:"
wget -q -O - "$eURL" > $SPAMHAUS_eDROP
grep -v '^;' $SPAMHAUS_eDROP | cut -d ' ' -f 1 > $eDROP_ADD_TO_UFW
echo " "
echo "Extract eDROP IP addresses and add to UFW:"
cat $eDROP_ADD_TO_UFW | while read line
do
/usr/sbin/ufw insert 1 deny from "$line" comment 'eDROP_Blacklisted_IPs'
done
echo " "
#####
## To remove or revert these rules, keep the list of IPs!
## Run a command like so to remove the rules:
# while read line; do ufw delete deny from $line; done < $ARCHIVE_FILE
#####
echo "Backup DROP IP address list:"
mv $DROP_ADD_TO_UFW $DROP_ARCHIVE_FILE
echo " "
echo "Backup eDROP IP address list:"
mv $eDROP_ADD_TO_UFW $eDROP_ARCHIVE_FILE
echo " "
echo End time: $(date)
