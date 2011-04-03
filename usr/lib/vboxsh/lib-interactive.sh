#!/bin/bash
depend_procedure core base # esp for auto_{network,locale,fstab}, intro and set_clock workers


# This is a port of the original /arch/setup script.  It doesn't use aif phases but uses it's own menu-based flow (phase) control

EDITOR=nano
BLOCK_ROLLBACK_USELESS=1

# clock
HARDWARECLOCK=
TIMEZONE=

# default filesystem specs (the + is bootable flag)
# <mountpoint>:<partsize>:<fstype>[:+]
DEFAULTFS="/boot:32:ext2:+ swap:256:swap /:7500:ext3 /home:*:ext3"

worker_vm_list_title='List Virtual Machines'
worker_vm_create_title='Create Virtual Machine'
worker_vm_modify_title='Modify Virtual Machine'
worker_vm_startstop_title='Start/Stop Virtual Machine'
worker_vm_delete_title='Delete Virtual Machine'
worker_vm_manage_iso_title='Mount/Unmount ISO Image'
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

	#TODO: why does a '2' appear instead of '' ??
	ask_option $default "MAIN MENU" '' required \
	"1" "$worker_select_source_title" \
	"2" "$worker_set_clock_title" \
	"3" "$worker_prepare_disks_title" \
	"4" "$worker_package_list_title" \
	"5" "$worker_install_packages_title" \
	"6" "$worker_configure_system_title" \
	"7" "$worker_install_bootloader_title" \
	"8" "Exit Install"
	case $ANSWER_OPTION in
	"1")
		                                        execute worker select_source; local ret=$?; [ $ret -eq 0 -a "$var_PKG_SOURCE_TYPE" = net ] && execute worker select_source_extras_menu
		                                                                                    [ $ret -eq 0 ] && execute worker runtime_packages             && NEXTITEM=2 ;;

        "2")
		                                        execute worker set_clock                                                                                  && NEXTITEM=3 ;;
        "3")
		                                        execute worker prepare_disks                                                                              && NEXTITEM=4 ;;
        "4")
		check_depend worker prepare_disks && \
		check_depend worker select_source    && execute worker package_list                                                                               && NEXTITEM=5 ;;
        "5")
		check_depend worker package_list && \
		check_depend worker select_source    && execute worker install_packages   && {                                    execute worker auto_fstab   ; \
		                                                                                                                  execute worker auto_locale  ; \
		                                                                                                                  execute worker auto_keymap_font;
		                                                                                                                  true                        ; } && NEXTITEM=6 ;;
        "6")
		check_depend worker install_packages && execute worker auto_network && \
		                                        execute worker configure_system   && {                                    execute worker mkinitcpio   ; \
		                                                                                                                  execute worker locales      ;
		                                                                                                                  execute worker initialtime  ;
		                                                                                                                  true                        ; } && NEXTITEM=7 ;;
        "7")
		check_depend worker configure_system && execute worker install_bootloader                                                                         && NEXTITEM=8 ;;
        "8")
		notify "If the install finished successfully, you can now type 'reboot' to restart the system." && stop_installer ;;
        *)
		ask_yesno "Abort Installation?" && stop_installer ;;
    esac
}


worker_configure_system()
{
	interactive_configure_system
}


worker_prepare_disks()
{
	interactive_prepare_disks
}


worker_select_source ()
{
	#TODO: how to handle user going here again? discard previous settings, warn him that he already done it?
	interactive_select_source && return 0
	return 1
}


worker_intro ()
{
	notify "Welcome to the Arch Linux Installation program. The install\
 process is fairly straightforward, and you should run through the options in\
 the order they are presented. If you are unfamiliar with partitioning/making\
 filesystems, you may want to consult some documentation before continuing.\
 You can view all output from commands by viewing your VC7 console (ALT-F7).\
 ALT-F1 will bring you back here.\n\n$DISCLAIMER"
}


worker_configure ()
{
	var_UI_TYPE=${arg_ui_type:-dia}
	ui_init
}


# select_packages()
# prompts the user to select packages to install
worker_package_list() {
	# if selection has been done before, warn about loss of input and let the user exit gracefully
	ended_ok worker package_list && ! ask_yesno "WARNING: Running this stage again will result in the loss of previous package selections.\n\nDo you wish to continue?" && return 0

	interactive_select_packages
}


worker_install_packages ()
{
	installpkg && return 0
	return 1
}


# Hand-hold through setting up networking
worker_runtime_network() {
	interactive_runtime_network
}


worker_select_mirror ()
{
	interactive_select_mirror
}


worker_install_bootloader ()
{
	interactive_install_bootloader
}


worker_auto_network ()
{
	ask=0
	# if the user has been through networking setup and if any of these variables is set, it may be useful to export the users' choices to the target system
	if [ "$S_DHCP" = 1 -o "$S_DHCP" = 0 ] && [ -n "$PROXY_HTTP$PROXY_FTP$DNS$INTERFACE$SUBNET$GW$BROADCAST" ]
	then
		ask=1
	# if the variables are not set but the network settings file exists, the user has probably run the runtime_network in a separate process (eg partial-configure-network)
	# in that case, lets source the file and check again
	elif [ -f $RUNTIME_DIR/aif-network-settings ] && source $RUNTIME_DIR/aif-network-settings && [ "$S_DHCP" = 1 -o "$S_DHCP" = 0 ] && [ -n "$PROXY_HTTP$PROXY_FTP$DNS$INTERFACE$SUBNET$GW$BROADCAST" ]
	then
		ask=1
	fi
	if [ "$ask" = 1 ]
	then
		ask_yesno "Do you want to use the network settings from the installer in rc.conf and resolv.conf?\n\nIf you used Proxy settings, they will be written to /etc/profile.d/proxy.sh" || return 0
		[ "$S_DHCP" = 1 ] && target_configure_network dhcp  "$PROXY_HTTP" "$PROXY_FTP" && return 0
		[ "$S_DHCP" = 0 ] && target_configure_network fixed "$PROXY_HTTP" "$PROXY_FTP" && return 0
		show_warning "Automatic network settings propagation failed" "Failed to import current network settings into target system"
		return 1
	fi
}
