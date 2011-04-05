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
	"7" "------------" \
	"8" "$title_exit"
	case $ANSWER_OPTION in
	"1")
		gen_vm_list
		#echo "--------------"
		#echo "$VMLIST"
		#echo "--------------"
		#dumpargs $VMLIST
		#exit
		# TODO ADD LOADING DIALOG
		ask_option 0 "VM's Present" '' required "0" "Return To Main Menu" "${VMLIST[@]}"
		VBoxManage showvminfo "${ANSWER_OPTION}" | less
		;;
        "2")
		ask_string "Please enter a name for the Virtual Machine." "Are you sure" "Are you sure?"
		#if [ -n $ANSWER_STRING ]; then
			vm_name=$ANSWER_STRING
			get_os_type		
				#if [ -n $ANSWER_OPTION ]; then
				vm_ostype=$ANSWER_OPTION
				ask_yesno "${vm_name} ${vm_ostype}" && echo "Blah"
				#fi
		#fi
		;;
        "3")
		;;
        "4")
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



