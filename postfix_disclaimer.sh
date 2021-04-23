#!/bin/sh

 # This file is part of a collection of bash scripts written and used by me which may be handy in server administration.
 #
 # (c) Corrado Mulas <tlc@mulas.me>
 #
 # For the full copyright and license information, please view the LICENSE
 # file that was distributed with this source code.
 
#Adds custom user signature (e.g. corporate signature with corporate/user contacts) to outgoing mail

INSPECT_DIR=/var/spool/filter
SENDMAIL=/usr/sbin/sendmail
UID=$(uuidgen)
DISCLAIMER_ADDRESSES=/etc/postfix/disclaimer_addresses

EX_TEMPFAIL=75
EX_UNAVAILABLE=69

trap "rm -f in.$$" 0 1 2 3 15

cd $INSPECT_DIR || { echo $INSPECT_DIR does not exist; exit
$EX_TEMPFAIL; }

cat >in.$$ || { echo Cannot save mail to file; exit $EX_TEMPFAIL; }

from_address=`grep -m 1 "From:" in.$$ | cut -d "<" -f 2 | cut -d ">" -f 1`

if [ `grep -wi ^${from_address}$ ${DISCLAIMER_ADDRESSES}` ]; then
/etc/postfix/your_signature_generator_script --user=$from_address --uuid=$UID

/usr/bin/altermime --input=in.$$ \
                   --disclaimer=/etc/postfix/filter/$UID.txt \
                   --disclaimer-html=/etc/postfix/filter/$UID.htm --force-for-bad-html --force-into-b64

rm /etc/postfix/filter/$UID.htm
rm /etc/postfix/filter/$UID.txt || \
                     { echo Message content rejected; exit $EX_UNAVAILABLE; }
rm /etc/postfix/filter/$UID.htm
rm /etc/postfix/filter/$UID.txt
fi

$SENDMAIL -oi "$@" <in.$$

exit $?
