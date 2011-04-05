#!/bin/bash
###### vboxsh VirtualBox Management Library ######
# This file should contain all the functions which interact
# with VBoxManage, and process it's output

gen_vm_list ()
{
   ### LOGIC
   # Clear out vmlist, get list of VM's, retrieve states,
   # all the while cleaning up text and pass it out into
   # vmlist for the calling function to use.
   > $TMPDIR/vboxlist.tmp
   vm_list=""
   VBoxManage -q list vms | while read line
   do
      tmp=${line#*\"}
      vmname=${tmp%\"*}
      state=`VBoxManage showvminfo "$vmname" | grep State`
      tmp=${state#*\:}
      state=${tmp%\(*}
      state=`echo "$state" | sed 's/^ *//;s/ *$//'`
      echo "\"$vmname\" \"$state\" \\" >> $TMPDIR/vmlist
      echo "my name is: ${vmname} and my state is: ${state}"
      vm_list=${vm_list}"p"$vmname" "$state
      echo "the contents of vm_list are: ${vm_list}"
      
   done
   echo "-----------------"
   echo $vm_list #> $TMPDIR/vmlistvarlib
   echo "-----------------"
   exit
}
