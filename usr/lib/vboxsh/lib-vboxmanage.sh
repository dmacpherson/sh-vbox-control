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
   pointer=0
   VBoxManage -q list vms >$TMPDIR/vmlistoutput
   while read line
   do
      tmp=${line#*\:}
      vmname=${tmp%\"*}
      state=`VBoxManage showvminfo "$vmname" | grep State`
      tmp=${state#*\:}
      state=${tmp%\(*}
      state=`echo "$state" | sed 's/^ *//;s/ *$//'`
      VMLIST[pointer]=${vmname}
      ((pointer++))
      VMLIST[pointer]=${state}
      ((pointer++))
   done < $TMPDIR/vmlistoutput

}


### Queuery ostypes known to the version of virtualbox installed
queuery_vbox_ostypes ()
{
   VBoxManage list ostypes | grep ':' >$TMPDIR/ostypes
   ### output of the call piped to stdin is in format:
   # ID:           vbox_ostype
   # Description:  friendly_name
   pointer=0
   # get raw output to process
   while read line
   do
      tmp=${line#*\:}
      type=`echo "$tmp" | sed 's/^ *//;s/ *$//'`
      OSTYPES[pointer]=${type}
      ((pointer++))
   done < $TMPDIR/ostypes
   ask_option 0 "Select an OS Type" '' required "0" "Other" "${OSTYPES[@]}"
}

worker_create_vm ()
{
   VBoxManage -q createvm --name "$cvm_name" --ostype "$cvm_ostype" --register
   VBoxManage -q modifyvm "$cvm_name" --memory $cvm_mem --acpi on --boot1 dvd --nic1 nat --hwvirtex on --pae on
   VBoxManage -q storagectl "$cvm_name" --name "IDE Controller" --add ide
   VBoxManage -q createvdi -filename "/datapool/virtualbox/harddrives/$cvm_name.vdi" -size $cvm_hdd --register
   VBoxManage -q storageattach "$cvm_name" --storagectl "IDE Controller" --port 0 --device 0 --type hdd --medium "/datapool/virtualbox/harddrives/$cvm_name.vdi"
   VBoxManage -q storageattach "$cvm_name" --storagectl "IDE Controller" --port 1 --device 0 --type dvddrive --medium "$cvm_iso"
}   
