#!/bin/bash
###### vboxsh VirtualBox Management Library ######
# This file should contain all the functions which interact
# with VBoxManage, and process it's output

############
# 

gen_vm_list ()
{
   unset VMLIST
   unset pointer
   pid=$$
   if [ "$(VBoxManage -q list vms >$TMPDIR/vm-list.$pid 2>$TMPDIR/vm-list-err.$pid)$?" ]
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
      done < $TMPDIR/vm-list.$pid
      rm $TMPDIR/vm-list*.$pid
   else
      alert_error $TMPDIR/vm-list-err.$$
   fi
}


############
### Query ostypes known to the version of virtualbox installed
worker_query_vbox_ostypes ()
{
   unset pointer

   if [ "$(`VBoxManage list ostypes | grep ':' >$TMPDIR/vbox-ostypes.$$ 2>$TMPDIR/vbox-ostypes-err.$$`)$?" ]
   then
      while read line
      do
         tmp=${line#*\:}
         type=`echo "$tmp" | sed 's/^ *//;s/ *$//'`
         OSTYPES[pointer]=${type}
         ((pointer++))
      done < $TMPDIR/vbox-ostypes
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
# $1 (req) registered VM name
worker_show_vm_info()
{
   echo "#########################################" > $TMPDIR/vm-info
   echo "# Detailed information for \""$1"\"" >> $TMPDIR/vm-info
   echo "# Please note this is NOT an editable configuration" >> $TMPDIR/vm-info
   echo "# Provided by: \`VBoxManage showvminfo \""$1"\"\`" >> $TMPDIR/vm-info
   echo "# Press 'Q' to Quit" >> $TMPDIR/vm-info
   echo -e "#########################################\n\n\n" >> $TMPDIR/vm-info
   VBoxManage showvminfo "$1" >> $TMPDIR/vm-info 2> $TMPDIR/vm-info-err && cat $TMPDIR/vm-info.$$ | less
   if [ $? ]
   then
      rm $TMPDIR/vm-info*
   else
      alert_error "$TMPDIR/vm-info-err"
   fi
}


############
# Worker to take snapshot of VM
# $1 (req) registered VM Name to take snapshot of
# $2 (req) name for snapshot
# $3 (opt) description for snapshot
# TODO: use dialog var
worker_take_snapshot ()
{
   unset opt_string
   if [ -n $3 ]
   then
      opt_string=$("--description \"$3\"")
   fi

   if [ "$4" = "1" ]
   then
      opt_string=$("$opt_string --pause")
   fi

   VBoxManage snapshot $1 take $2 $optstring &>$TMPDIR/vm-snapshot | dialog --tailbox $TMPDIR/vm-snapshot 0 0


}


#########
# Worker to restore snapshot
# $1 (req) VM Name
# $2 (req) snapshot name to restore
worker_snapshot_restore ()
{
   VBoxManage snapshot $1 restore $2 >> $TMPDIR/vm-snapshot-restore.$$ 2> $TMPDIR/vm-snapshot-restore-err
   if [ "$?" ]
   then
      rm $TMPDIR/vm-snapshot-restore
   else
      alert_error "$TMPDIR/vm-snapshot-restore-err"
   fi
}

#########
# Worker to issue start/stop commands to VM
# $1 (req) signal to send to vm
# $2 (req) VM to send signal to
# $3 (opt) headless configuration string -n -m yourport -o yourpassword
# TODO: Error handling
worker_startstop_vm ()
{
   if [[ "$1" = "pause" || "$1" = "resume" || "$1" = "reset" || "$1" = "poweroff" || "$1" = "savestate" ]]
   then
      VBoxManage controlvm $2 $1 
   fi

   if [ "$1" = "start" ]
   then
      sleep 1
      #VBoxHeadless
      nohup VBoxHeadless -s $2 $3 > /dev/null 2>&1 &
   fi
}




