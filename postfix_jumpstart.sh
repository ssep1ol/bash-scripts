#!/bin/bash
 
 # This file is part of a collection of bash scripts written and used by me which may be handy in server administration.
 #
 # (c) Corrado Mulas <tlc@mulas.me>
 #
 # For the full copyright and license information, please view the LICENSE
 # file that was distributed with this source code.
 
#Please don't run in short intervals if your server processes a truckload of emails, or it will restart postfix and amavis even when everything is ok, slowing down operations. 
#This script is a dumb way to restart Amavis when it suddenly decides to commit suicide with no apparent reason, avoiding prevention of mail processing. It restarts daemons, then flushes your queue.
#For a more clever solution, you may use and properly configure Monit.
#mail@example.com is a mail address where you will be notified when a restart attempt occurs.

QUEUE=$(mailq | grep -c "^[A-F0-9]")
TIME=$(date)


if [ "$QUEUE" -eq "0" ];then
  echo "OK";
else
        echo "Stuck mail queue detected, restarting postfix...";
        systemctl restart amavis;
        systemctl restart postfix;
        mail -s "[$(hostname)] Mail server restarted due to stuck deferred messages in queue" mail@example.com <<< "There were $QUEUE messages stuck in Postfix's queue. An automatic mail server restart attempt has been done. Timestamp: $TIME";
        postqueue -f;
fi
