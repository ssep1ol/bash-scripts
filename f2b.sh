#!/bin/bash

 # This file is part of a collection of bash scripts written and used by me which may be handy in server administration.
 #
 # (c) Corrado Mulas <tlc@mulas.me>
 #
 # For the full copyright and license information, please view the LICENSE
 # file that was distributed with this source code.
 
DATE=$(date)
LOGPATH=""
LOGHTMLPATH=""

rm -rf $LOGPATH

touch $LOGPATH
/usr/bin/f2b-statusall > $LOGPATH
chmod 600 $LOGPATH
chown www-data:www-data $LOGPATH

rm -rf $LOGHTMLPATH

touch $LOGHTMLPATH
/usr/bin/f2b-statusall > $LOGHTMLPATH

sed -i "1s;^;<pre>\nLast updated: $DATE \n;" $LOGHTMLPATH
echo '</pre>' | tee -a $LOGHTMLPATH > /dev/null


chmod 600 $LOGHTMLPATH
chown www-data:www-data $LOGHTMLPATH
