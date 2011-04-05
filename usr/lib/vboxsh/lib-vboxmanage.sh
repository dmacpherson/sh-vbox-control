#!/bin/bash
###### vboxsh VirtualBox Management Library ######

vbox_list_vms ()
{
   echo > $TMPDIR/vboxlist.tmp
   VBoxManage -q list vms | while read line
   do
      tmp=${line#*\"}
      vmname=${tmp%\"*}
      state=`VBoxManage showvminfo "$vmname" | grep State`
      tmp=${state#*\:}
      state=${tmp%\(*}
      state=`echo "$state" | sed 's/^ *//;s/ *$//'`
      echo "\"$vmname\" \"$state\" \\" >> $TMPDIR/vboxlist.tmp
   done
exit
}
