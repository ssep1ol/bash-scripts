#!/bin/bash

 # This file is part of a collection of bash scripts written and used by me which may be handy in server administration.
 #
 # (c) Corrado Mulas <tlc@mulas.me>
 #
 # For the full copyright and license information, please view the LICENSE
 # file that was distributed with this source code.
 
QUEUE=$(mailq | grep -c "^[A-F0-9]")
TIME=$(date)
#echo $QUEUE

if [ "$QUEUE" -eq "0" ];then
  echo "OK";
else
  echo "Stuck mail queue detected, restarting postfix...";
  systemctl restart amavis;
  systemctl restart postfix;
  mail -s "[$(hostname)] Mail server restarted due to stuck deferred messages in queue" areait@runpolito.it <<< "There were $QUEUE messages stuck in Postfix's queue. An automatic mail server restart attempt has been done. Timestamp: $TIME";
  postqueue -f;
fi
