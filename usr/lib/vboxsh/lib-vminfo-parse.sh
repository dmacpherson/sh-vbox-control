#!/bin/bash

############
# lib-vmparse
# library to parse the output of VBoxManage -showvminfo "$vm_name"
# NOTE that most functions in here will interact with a tempfile containing the output 

############
# parse the entire vminfo
# $1 (req) output file to parse
vmparse_master ()
{
 vmparse_snapshot $1
}



############
# parse the output to retrieve a list of snapshots for a particular VM
# $1 file to parse
# Returns an array "name1" "uuid1" "name2" "uuid2" ...
vmparse_snapshot ()
{
   _snapshots=$(`sed -e '/^$/d' -e 's/^\s*Name: //g' -e '/^Snapshots:/,$b' -e 'd' <$1 | grep -v "^Snapshots:"`)
   unset pointer
   unset _snap_array
   while read line
      VMSNAPSHOTS[pointer]=$(`echo "${line%(*}" | sed -e 's/^ *//;s/ *$//'`)
      ((pointer++))
      if [ -n $(`echo "$line" | grep "\* *$"`)
      then #this is current snapshot
         VMSNAPSHOTS[pointer]="(current)"
      else
         VMSNAPSHOTS[points]=" "
      fi
   do
   done <_snapshots  
}
