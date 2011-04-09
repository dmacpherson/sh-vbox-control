#!/bin/bash
EDITOR=nano

title_vm_list='Show Registered VMs'
title_vm_create='Create Virtual Machine'
title_vm_modify='Modify Virtual Machine'
title_vm_startstop='Start/Stop Virtual Machine'
title_vm_delete='Delete Virtual Machine'
title_vm_manage_iso='Mount/Unmount ISO Image'
title_exit='Exit'

start_interactive ()
{
	#####################
	## begin execution ##
	
	while true
	do
    		mainmenu
	done
}


mainmenu()  
{
   default=no
   #
   ask_option $default "MAIN MENU" '' required \
   "1" "$title_vm_list" \
   "2" "$title_vm_create" \
   "3" "$title_vm_modify" \
   "4" "$title_vm_startstop" \
   "5" "$title_vm_delete" \
   "6" "$title_vm_manage_iso" \
   "7" "--------------------" \
   "8" "$title_exit"

   case $ANSWER_OPTION in
   "1") ### show registered VMs
      show_registered
      ;;
   "2")
      create_vm_settings
      ;;
   "3")
      ;;
   "4")
      gen_vm_list
      # TODO ADD LOADING DIALOG
      ask_option 0 "Pick your VM to Start/Stop/Etc." '' required "0" "Return To Main Menu" "${VMLIST[@]}"
	if [ $ANSWER_OPTION = 0 ]; then return; fi
      machine_name_temp=$ANSWER_OPTION
      start_stop_vm
      ;;
   "5")
      ;;
   "6") ###Manage ISO
      ;;
   "7") ###-----------
      ;;
   "8")	#TODO do any cleanups and wait for any open PID's that need monitoring.
      exit_vboxsh ;;
   *)
     ask_yesno "Are you sure you want to exit?" && exit_vboxsh ;;
   esac
}


worker_intro ()
{
   notify "$DISCLAIMER"
}



create_vm_settings ()
{
   ###Clean creation slate, logic depends on "not-nulls"
   cvm_name=""
   cvm_ostype=""
   cvm_mem=""
   cvm_hdd=""
   cvm_iso=""
   exitcode=0

   while [[ -z "$cvm_name" && "$exitcode" -ne 1 ]] 
   do
      ask_string "Please enter a name for the Virtual Machine."
      dialog --msgbox "$exitcode" 10 30
      cvm_name=${ANSWER_STRING}
   done

   while [ -z "$cvm_ostype" ]
   do
      worker_query_vbox_ostypes
      cvm_ostype=${ANSWER_OPTION}
   done

   while [ -z "$cvm_mem" ]
   do
      ask_number "Please enter the size of the virtual machine's memory in MiB (1024 = 1 Gib)"
      cvm_mem=${ANSWER_NUMBER}
   done

   while [ -z "$cvm_hdd" ]
   do
      ask_number "Please enter the size of the virtual machine's hard drive in MiB (1024 = 1 GiB)"
      cvm_hdd=${ANSWER_NUMBER}
   done

   while [ -z "$cvm_iso" ]
   do
      ask_string "Please enter the path to the CD/DVD Image you would like to use"
      if [ -f "${ANSWER_STRING}" ]
      then
         cvm_iso=${ANSWER_STRING}
      fi
   done
   
   confirmation="\nName:     $cvm_name\nOs Type:  $cvm_ostype\nMemory:   $cvm_mem\nHDD Size: $cvm_hdd\nISO:      $cvm_is"
   if [ ask_yesno --ask "These are the settings you have chosen for your VM. If these settings are correct click [Create], otherwise you may [Cancel] to return to the main menu.$confirmation" --cr-wrap ]
   then
      notify "I got here."
   fi

#worker_create_vm &> $TMPDIR/createvm | dialog --tailbox /$TMPDIR/createvm 0 0
}


start_stop_vm ()
{
        local state=""
	local tmp=""

        #Grab the machines current State
        state=`VBoxManage showvminfo "$machine_name_temp" | grep State`
        tmp=${state#*\:}
        state=${tmp%\(*}
        state=`echo "$state" | sed 's/^ *//;s/ *$//'`

        #Depending on the state of the machine - this case will give user different options
        case $state in
                "running")
                        ask_option "no" "\"$machine_name_temp\" is currently \"$state\" Choose one of the below options:" '' required \
                        "pause" "Pause machine as is" \
                        "savestate" "Savestate is similar to hibernate" \
                        "reset" "Reset the VM" \
                        "poweroff" "Power Off the vm" \
                        "acpipowerbutton" "Like pressing power button" \
                        "acpisleepbutton" "Like pressing sleep button"
                        worker_startstop_vm $ANSWER_OPTION $machine_name_temp
                        ;;
                "paused")
                        ask_option "no" "\"$machine_name_temp\" is currently \"$state\" Choose one of the below options:" '' required \
                        "resume" "Resume machine" \
                        "poweroff" "Power Off the vm"
                        worker_startstop_vm $ANSWER_OPTION $machine_name_temp
                        ;;
                *)
			#This should catch any VM's that are Powered Off, Saved, Aborted - Their only options are to Start
                        ask_option "no" "\"$machine_name_temp\" is currently \"$state\" Choose one of the below options:" '' required \
                        "start" "Start the VM"
                        worker_startstop_vm $ANSWER_OPTION $machine_name_temp
                        ;;
        esac
}

show_registered ()
{
   while true
   do
      please_wait "Loading list of currently registered VM's"
      gen_vm_list
      # TODO ADD LOADING DIALOG
      ask_option 0 "Currently registered VMs" "\n\nPlease select one for more information..." required "0" "Return To Main Menu" "${VMLIST[@]}"
      if [ $ANSWER_OPTION ]; then return; fi
      vm_manage_root "$ANSWER_OPTION"
   done
}


############
# manage selected vm
# $1 VM name
# NOTE: Detailed information is parsed before display of this menu
#   by vmparse_master() in lib-vminfo-parse.sh See there for more information
vm_manage_root ()
{
   _manage_options=("0" "Return to Main Menu"\
                    "1" "Show Detailed Information"\
                    "2" "Snapshots"\
                    "3" " "\
                    "4" " "\
                    "5" " "\
                    "6" " "\
                    "7" " "\
                    "8" " "\
                    "9" " ")

   please_wait "Loading detailed information on selected VM..."
   VBoxManage showvminfo "$1" > $TMPDIR/vm-manage 2>$TMPDIR/vm-manage-err
   vmparse_master "$TMPDIR/vm-manage"

   while true #Keep looping until they choose to return to main menu
   do 
      ask_option 0 "Managing \"$1\"..." '' required "${_manage_options[@]}"
      case $ANSWER_OPTION in
      "0")
         return ;;
      "1")
         worker_show_vm_info "$1"
         ;;
      "2")
         vm_manage_snapshots "$1" ;;
      esac
   done
}

############
# Manage snapshots for chosen vm 
# $1 vm_name
# $2 PID for vm-manage info
vm_manage_snapshots () \
{
   _manage_snapshots=("0" "Return to Previous Menu"\
                  "1" "List Snapshots"\
                  "2" "Take Snapshot"\
                  "3" "Restore Snapshot "\
                  "4" "Delete Snapshot "\
                  "5" " ")

   while true
   do
      ask_option 0 "Managing snapshots for \"$1\"..." '' required "${_manage_snapshots[@]}"
      case $ANSWER_OPTION in
      "0")
         return
         ;;
      "1")ask_option 0 "Snapshots for \"$1\"" '' required "0" "Return to Previous Menu" "${VMSNAPSHOTS[@]}" 
         if [ $ANSWER_OPTION ]
         then
            continue
         else
            alert_error "We're sorry, this function is not yet available."   
         fi
         ;;
      "2") # Take snapshot
         ask_yesno "Are you sure you want to take a snapshot of \"$1\""
         #echo "exit code was \"$?\""
         if [[ $? -eq 0 ]]
         then
            ask_string "Please enter a name for this snapshot."
            if [ -n $ANSWER_STRING ] 
            then 
               _snapname=$ANSWER_STRING
            else
               inform "Invalid name! Returning to previous menu..."
               return
            fi
            
            worker_get_vm_state
            if [ "$VMSTATE" = "running" ]
            then
               if [ ask_yesno "\"$1\" is currently Running.\n Do you want to pause before taking the snapshot?" ]
               then
                  worker_take_snapshot "$1" "$_snapname" 1
                  if [ask_yesno "You chose to pause \"$1\" to take the snapshot.\n\nDo you want to resume the machine now?" ]
                  then 
                     worker_startstop_vm "resume" "$1"
                  fi 
               else
                  worker_take_snapshot "$1"
               fi
            else
               worker_take_snapshot "$1"
            fi
         else
            continue
         fi
         ;;
      "3") # Restore snapshot
         ask_option 0 "Select snapshot to restore." '' required "0" "Return to Previous Menu" "${VMSNAPSHOTS[@]}" 
         if [ $ANSWER_OPTION ]
         then
            continue
         else
            if [ -n $ANSWER_OPTION ]
            then
               ask_yesno "Are you sure you want to restore the snapshot: \"$ANSWER_OPTION\""
               if [ $ANSWER_YESNO ]
               then
                  worker_snapshot_restore "$1" "$ANSWER_OPTION"
               fi
            fi
         fi
         ;;
      "4") # Delete snapshot
         ask_option 0 "Select snapshot to delete." '' required "0" "Return to Previous Menu" "${VMSNAPSHOTS[@]}" 
         if [ $ANSWER_OPTION = "0" ]
         then
            continue
         else
            ask_yesno "Are you sure you want to delete...\nSnapshot:          \"$ANSWER_OPTION\"\nWhich belongs to: \"$1\"\nThis action cannot be undone."
            if [ $ANSWER_YESNO ]
            then
               [ -n $ANSWER_OPTION ] && worker_snapshot_restore "$1" "$ANSWER_OPTION"   
            else
               continue
            fi   
         fi 
         ;;
      esac
   done


}
