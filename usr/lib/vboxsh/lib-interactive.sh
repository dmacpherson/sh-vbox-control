#!/bin/bash
EDITOR=nano

title_vm_list='List Virtual Machines'
title_vm_create='Create Virtual Machine'
title_vm_modify='Modify Virtual Machine'
title_vm_startstop='Start/Stop Virtual Machine'
title_vm_delete='Delete Virtual Machine'
title_vm_manage_iso='Mount/Unmount ISO Image'
title_exit='Exit'
vm_list=""
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
	[ -n "$NEXTITEM" ] && default="$NEXTITEM"

	#
	ask_option $default "MAIN MENU" '' required \
	"1" "$title_vm_list" \
	"2" "$title_vm_create" \
	"3" "$title_vm_modify" \
	"4" "$title_vm_startstop" \
	"5" "$title_vm_delete" \
	"6" "$title_vm_manage_iso" \
	"7" "-------------------" \
	"8" "$title_exit"
	case $ANSWER_OPTION in
	"1")
		gen_vm_list
		# TODO ADD LOADING DIALOG
		ask_option 0 "VM's Present" '' required "0" "Return To Main Menu" "${VMLIST[@]}"
		echo "#########################################" > $TMPDIR/vminfo
                echo "# VM Info for machine \""$ANSWER_OPTION"\"" >> $TMPDIR/vminfo
                echo "# NOTE: This is not an editable configuration" >> $TMPDIR/vminfo
                echo "# Provided by: VBoxManage showvminfo \""${ANSWER_OPTION}"\"" >> $TMPDIR/vminfo
                echo "# Press 'Q' to Quit" >> $TMPDIR/vminfo
                echo "#########################################" >> $TMPDIR/vminfo
                VBoxManage showvminfo "${ANSWER_OPTION}" >> $TMPDIR/vminfo && cat $TMPDIR/vminfo | less
		;;
        "2")
		create_vm_settings
		;;
        "3")
		;;
        "4")
                gen_vm_list
                # TODO ADD LOADING DIALOG
                ask_option 0 "VM's Present" '' required "0" "Return To Main Menu" "${VMLIST[@]}"
		machine_name_temp=$ANSWER_OPTION
		ask_option 1 "Select action to perform" '' required "0" "Return to Main Menu" "1" "pause" "2" "resume" "3" "reset" "4" "poweroff" "5" "savestate" 
"6" "acpipowerbutton" "7" "acpisleepbutton"
		ask_yesno "Do you want to $ANSWER_OPTION on the VM named $machine_name_temp" && VBoxManage controlvm $machine_name_temp $ANSWER_OPTION
		;;
        "5")
		;;
        "6")
		;;
        "7")
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


#file_selector ()
#{
#   target="\/"
#   
#   while [ -d "$target" ]
#   do
#      
#   done
#}

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
      queuery_vbox_ostypes
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
   worker_create_vm

}
