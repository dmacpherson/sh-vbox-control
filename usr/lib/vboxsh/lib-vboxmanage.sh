#!/bin/bash
###### vboxsh VirtualBox Management Library ######

vbox_list_vms ()
{
   VBoxManage -q list vms | while read line
   do
      tmp=${line#*\"}
      vmname=${tmp%\"*}
      state=`VBoxManage showvminfo "$vmname" | grep State`
      tmp=${state#*\:}
      state=${tmp%\(*}
      state=`echo "$state" | sed 's/^ *//'`
      echo "\"$vmname\" \"$state\" \\" > $TMPDIR/vboxlist.tmp
   done
exit
}
