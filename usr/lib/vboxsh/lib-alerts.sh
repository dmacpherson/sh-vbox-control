#!/bin/bash

##### lib-alerts.sh

############
# $1 (optional) extra information
alert_wait ()
{
   inform "Please wait while the request is processed.\nThis may take a moment...\n\n$1"
}


############
# $1 (suggested) location of stderr output or more information
alert_error ()
{
   if [ -f $1 ] 
      then $1="More information can be found in the file:\n$1" 
   fi
   inform "There was an error processing your request...\n\n$1"
}


