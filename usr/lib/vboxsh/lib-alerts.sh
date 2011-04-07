#!/bin/bash

##### lib-alerts.sh

############
# $1 (optional) extra information
please_wait ()
{
   inform "\nPlease wait while the request is processed.\nThis may take a moment...\n\n$1"
}


############
# $1 (sug) location of stderr output or more information
# $2 (opt) optional additional text
alert_error ()
{
   if [ -f $1 ] 
      then notify "There was an error processing your request...\n$2\nMore information can be found at $1" 
   fi
   notify "There was an error processing your request...\n$2"
}


