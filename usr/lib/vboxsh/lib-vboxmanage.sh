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
         if [ "$state" = "running" ] ; then
                get_vnc_port_number $vmname
         fi
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

########
###This Gets the VNC Port number of Running machines to show in list.
###TODO:  Test in Linux - Only works with port numbers 4 digits long.
###Will Need Adjusting: Forgot to take passwords into account -- Wont work if a password is added.. :(
get_vnc_port_number ()
{
        local GrabVNCPort=`ps aux | grep $1 | egrep '(--vnc|-n -m)'`
        if [ "$GrabVNCPort" != "" ] ; then
                local tmp=`echo ${GrabVNCPort:(-4)}`
                state="running VNC Port $tmp"
        fi
}

############
### Query ostypes known to the version of virtualbox installed
### TODO: Remove interactive portions to appropriate script.
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
# $1 (req) NAME for machine
# $2 (req) OS TYPE
# $3 (req) HDD SIZE
# $4 (req) ISO Location
# $5 (req) VDI Location as /path/to/location
worker_create_vm ()
{
   VBoxManage -q createvm --name "$1" --ostype "$2" --register 
   VBoxManage -q modifyvm "$1" --memory $cvm_mem --acpi on --boot1 dvd --nic1 nat --hwvirtex on --pae on
   VBoxManage -q storagectl "$1" --name "IDE Controller" --add ide 
   VBoxManage -q createvdi -filename "$5/$1.vdi" -size $3 --register
   VBoxManage -q storageattach "$1" --storagectl "IDE Controller" --port 0 --device 0 --type hdd --medium "/mnt/raid/tmp/$1.vdi"
   VBoxManage -q storageattach "$1" --storagectl "IDE Controller" --port 1 --device 0 --type dvddrive --medium "$4"
}


############
# Shows detailed info for selected VM
# $1 (req) registered VM name or UUID
# TODO: interactivity... Should we move the information display to another script?
worker_show_vm_info()
{
   ask_yesno "got here"
   echo "#########################################" > $TMPDIR/vm-info
   echo "# Detailed information for \""$1"\"" >> $TMPDIR/vm-info
   echo "# Please note this is NOT an editable configuration" >> $TMPDIR/vm-info
   echo "# Provided by: \`VBoxManage showvminfo \""$1"\"\`" >> $TMPDIR/vm-info
   echo "# Press 'Q' to Quit" >> $TMPDIR/vm-info
   echo -e "#########################################\n\n\n" >> $TMPDIR/vm-info
   VBoxManage showvminfo "$1" >> $TMPDIR/vm-info 2> $TMPDIR/vm-info-err && cat $TMPDIR/vm-info | less
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
# $4 (opt) pause flag. "1" pauses VM. All other values ignored 
# TODO: use utilize libui
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

   VBoxManage snapshot "$1" take "$2" $optstring &>$TMPDIR/vm-snapshot | dialog --tailbox $TMPDIR/vm-snapshot 0 0


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
# $3 (opt) VNC Port
# $4 (opt) Password for VNC
# ARGVs 3&4 Are usedfor starting a machine headless
# TODO: Error handling for VBoxManage controls
# TODO: Remove interactive portions to appropriate script
#   This lib is non-interactive and should house ONLY workers.
worker_startstop_vm ()
{
	if [[ "$1" = "pause" || "$1" = "resume" || "$1" = "reset" || "$1" = "poweroff" || "$1" = "savestate" || "$1" = "acpipowerbutton" || "$1" = "acpisleepbutton" ]]
		then
			VBoxManage controlvm $2 $1 > /dev/null 2>&1 &
	fi
	if [ "$1" = "start" ] ; then
		local vnc_port_num=""
		local vnc_password=""
		ask_number "Please Enter VNC Port Number\n( Leave Blank for No VNC Access )\n" 5900 5999
		if [[ $ANSWER_NUMBER != "" ]] ; then
			vnc_port_num="-n -m ${ANSWER_NUMBER}"
			ask_string "Please Enter Password for VNC Access (Leave Blank for None):"
			if [[ "$ANSWER_STRING" != "" ]] ; then
				vnc_password="-o ${ANSWER_STRING}"
			fi
		fi
		VBoxHeadless -s $2 $vnc_port_num $vnc_password > /dev/null 2>&1 &
	fi
}

############
# Worker that returns the state of a VM
# $1 (req) VM Name or UUID
worker_get_vm_state ()
{
   VMSTATE=`echo "${${\`VBoxManage showvminfo "$1" | grep "^State: "\`#*\:}%\(*}" | sed 's/^ *//;s/ *$//'`
}
