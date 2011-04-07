#!/bin/bash
###### vboxsh VirtualBox Management Library ######
# This file should contain all the functions which interact
# with VBoxManage, and process it's output

gen_vm_list ()
{
   pointer=0
   if [ VBoxManage -q list vms >$TMPDIR/vm-list.$$ 2>$TMPDIR/vm-list-err.$$ ]
   then
      while read line
      do
         tmp=${line#*\"}
         vmname=${tmp%\"*}
         state=`VBoxManage showvminfo "$vmname" | grep State`
         tmp=${state#*\:}
         state=${tmp%\(*}
         state=`echo "$state" | sed 's/^ *//;s/ *$//'`
         VMLIST[pointer]=${vmname}
         ((pointer++))
         VMLIST[pointer]=${state}
         ((pointer++))
      done < $TMPDIR/vmlistoutput.$$
   else
      alert_error $TMPDIR/vm-list-err
   fi
}


############
### Query ostypes known to the version of virtualbox installed
worker_query_vbox_ostypes ()
{
   pointer=0

   if [ VBoxManage list ostypes | grep ':' >$TMPDIR/vbox-ostypes.$$ 2>$TMPDIR/vbox-ostypes-err.$$ ]
   then
      while read line
      do
         tmp=${line#*\:}
         type=`echo "$tmp" | sed 's/^ *//;s/ *$//'`
         OSTYPES[pointer]=${type}
         ((pointer++))
      done < $TMPDIR/ostypes
      ask_option 0 "Select an OS Type" '' required "0" "Other" "${OSTYPES[@]}"
   else
      notify_error "$TMPDIR/vbox-ostypes-err.$$"
   fi
}


############
# Creates a VM
# TODO: Convert to passed arguments,
# TODO: Default folder as var, selectable
# TODO: Direct output to log and infobox it.
worker_create_vm ()
{
   VBoxManage -q createvm --name "$cvm_name" --ostype "$cvm_ostype" --register 
   VBoxManage -q modifyvm "$cvm_name" --memory $cvm_mem --acpi on --boot1 dvd --nic1 nat --hwvirtex on --pae on
   VBoxManage -q storagectl "$cvm_name" --name "IDE Controller" --add ide 
   VBoxManage -q createvdi -filename "/mnt/raid/tmp/$cvm_name.vdi" -size $cvm_hdd --register
   VBoxManage -q storageattach "$cvm_name" --storagectl "IDE Controller" --port 0 --device 0 --type hdd --medium "/mnt/raid/tmp/$cvm_name.vdi"
   VBoxManage -q storageattach "$cvm_name" --storagectl "IDE Controller" --port 1 --device 0 --type dvddrive --medium "$cvm_iso"
}


############
# Shows detailed info for selected VM
# $1 (required) registered VM name
worker_show_vm_info()
{
   echo "#########################################" > $TMPDIR/vm-info.$$
   echo "# Detailed information for \""$1"\"" >> $TMPDIR/vm-info.$$
   echo "# Please note this is NOT an editable configuration" >> $TMPDIR/vm-info.$$
   echo "# Provided by: \`VBoxManage showvminfo \""$1"\"\`" >> $TMPDIR/vm-info.$$
   echo "# Press 'Q' to Quit" >> $TMPDIR/vm-info.$$
   echo -e "#########################################\n\n\n" >> $TMPDIR/vm-info.$$
   if [ VBoxManage showvminfo "$1" >> $TMPDIR/vm-info.$$ 2> $TMPDIR/vm-info-err.$$ && cat $TMPDIR/vm-info.$$ | less ]
   then
      rm $TMPDIR/vm-info*$$
   else
      alert_error "$TMPDIR/vm-info-err.$$"
   fi
}
