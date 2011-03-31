#!/bin/sh
userinput() {
	dialog --title "$1" --clear --inputbox "$2" -1 -1 "$3" 2> /tmp/inputbox.tmp.$$
	retval=$?
	case $retval in
	  0)
		input=`cat /tmp/inputbox.tmp.$$`;;
	  1)
		input='';;
	  255)
		input='';;
	esac
	rm -f /tmp/inputbox.tmp.$$
}
loop=0 
while [ $loop -le 0 ]
	do
		dialog --title "VirtualBox Control" --menu \
		"Choose one of the following or press <Cancel> to exit" \
		15 50 7 \
   		"0" "Exit" \
		"1" "Create Virtual Machine" \
   		"2" "Modify Virtual Machine" \
   		"3" "Mount/Unmount CD/DVD Image" \
		"4" "Start/Stop Virtual Machine" \
		"5" "Delete Virtual Machine" 2>/tmp/menu.tmp
		retval=$?
	        case $retval in
        	  0)
          	        choice=`cat /tmp/menu.tmp`;;
         	  1)
                	break;;
         	  255)
                	break;;
        	esac
        	rm -f /tmp/menu.tmp
	
	case $choice in
	  0)
		break;;
	  1)
		$input=''
		userinput "VirtualBox Control - Name" "Enter the name of the virtual machine."
		temp1=$input
		if [ -n "$input" ]; then
		dialog --title "VirtualBox Control - OS Type" --menu \
                "Choose one for the OS Type or press <Cancel> to exit" \
                18 50 10 \
                "Windows31" "Windows 3.1" \
                "Windows95" "Windows 95" \
                "Windows98" "Windows 98" \
		"WindowsMe" "Windows Me" \
                "WindowsNT4" "Windows NT4" \
                "Windows2000" "Windows 2000" \
                "WindowsXP" "Windows XP" \
                "WindowsXP_64" "Windows XP (64 bit)" \
                "Windows2003" "Windows 2003" \
                "Windows2003_64" "Windows 2003 (64 bit)" \
                "WindowsVista" "Windows Vista" \
                "WindowsVista_64" "Windows Vista (64 bit)" \
                "Windows2008" "Windows 2008" \
                "Windows2008_64" "Windows 2008 (64 bit)" \
                "Windows7" "Windows 7" \
                "Windows7_64" "Windows 7 (64 bit)" \
                "WindowsNT" "Other Windows" \
                "Linux24" "Linux Kernel 2.4" \
                "Linux24_64" "Linux Kernel 2.4 (64 bit)" \
                "Linux26" "Linux Kernel 2.6" \
                "Linux26_64" "Linux Kernel 2.6 (64 bit)" \
                "ArchLinux" "ArchLinux" \
                "ArchLinux_64" "ArchLinux (64 bit)" \
                "Debian" "Debian" \
                "Debian_64" "Debian (64 bit)" \
                "OpenSUSE" "OpenSUSE" \
                "OpenSUSE_64" "OpenSUSE (64 bit)" \
                "Fedora" "Fedora" \
                "Fedora_64" "Fedora (64 bit)" \
                "Gentoo" "Gentoo" \
                "Gentoo_64" "Gentoo (64 bit)" \
                "Mandriva" "Mandriva" \
                "Mandriva_64" "Mandriva (64 bit)" \
                "RedHat" "RedHat" \
                "RedHat_64" "RedHat (64 bit)" \
                "Turbolinux" "Turbolinux" \
                "Ubuntu" "Ubuntu" \
                "Ubuntu_64" "Ubuntu (64 bit)" \
                "Xandros" "Xandros" \
                "Xandora_64" "Xandros (64 bit)" \
                "Oracle" "Oracle" \
                "Oracle_64" "Oracle (64 bit)" \
                "Linux" "Other Linux" \
                "Solaris" "Solaris" \
                "Solaris_64" "Solaris (64 bit)" \
                "OpenSolaris" "OpenSolaris" \
                "OpenSolaris_64" "OpenSolaris (64 bit)" \
                "FreeBSD" "FreeBSD" \
                "FreeBSD_64" "FreeBSD (64 bit)" \
                "OpenBSD" "OpenBSD" \
                "OpenBSD_64" "OpenBSD (64 bit)" \
                "NetBSD" "NetBSD" \
                "NetBSD_64" "NetBSD (64 bit)" \
                "OS2Warp3" "OS2Warp3" \
                "OS2Warp4" "OS2Warp4" \
                "OS2Warp45" "OS2Warp45" \
                "OS2eCS" "OS2eCS" \
                "OS2" "OS2" \
                "MacOS" "Mac OS" \
                "MacOS_64" "Mac OS (64 bit)" \
                "DOS" "DOS" \
                "Netware" "Netware" \
                "L4" "L4" \
                "QNX" "QNX" 2>/tmp/menu.tmp
                retval=$?
                case $retval in
                  0)
                        input=`cat /tmp/menu.tmp`;;
                  1)
                        input='';;
                  255)
                        input='';;
                esac
                rm -f /tmp/menu.tmp
		temp2=$input
		fi
		if [ -n "$input" ]; then
		userinput "VirtualBox Control - Memory" "Please choose the amount of memory \n for the VM in MB. Ex: 512 or 1024" "512"
		temp3=$input
		fi
		if [ -n "$input" ]; then
		userinput "VirtualBox Control - Hard Drive" "How much hard drive space\n do you want to give the virtual machine.\n Specify in MB, Ex: 20000 = 20GB. " "20000"
		temp4=$input;
		fi
		if [ -n "$input" ]; then
		userinput "VirtualBox Control - DVD/CD Image" "Enter the full path to the DVD/CD Image to Mount\n Leave blank to mount later.\n Ex: /mnt/external/images/ubuntu.iso" "/datapool/public/programs/Images/"
		temp5=$input;
		dialog --title "VirtualBox Control - Confirm VM Creation" --yesno "Please verify the VM settings before creation.\n\nName: $temp1\nType: $temp2\nMemory: $temp3 MB\nHard Drive Space: $temp4 MB\nDVD/CD ISO Location:\n$temp5" 15 60
		case $? in
		0)
			VBoxManage -q createvm --name "$temp1" --ostype $temp2 --register >> /tmp/vmcreateoutput.tmp.$$
			VBoxManage -q modifyvm "$temp1" --memory $temp3 --acpi on --boot1 dvd --nic1 nat --hwvirtex on --pae on >> /tmp/vmcreateoutput.tmp.$$
			VBoxManage -q storagectl "$temp1" --name "IDE Controller" --add ide >> /tmp/vmcreateoutput.tmp.$$
			VBoxManage -q createvdi -filename "/datapool/virtualbox/harddrives/$temp1.vdi" -size $temp4 -register >> /tmp/vmcreateoutput.tmp.$$
			VBoxManage -q storageattach "$temp1" --storagectl "IDE Controller" --port 0 --device 0 --type hdd --medium "/datapool/virtualbox/harddrives/$temp1.vdi" >> /tmp/vmcreateoutput.tmp.$$
			VBoxManage -q storageattach "$temp1" --storagectl "IDE Controller" --port 1 --device 0 --type dvddrive --medium "$temp5" >> /tmp/vmcreateoutput.tmp.$$
			dialog --textbox /tmp/vmcreateoutput.tmp.$$ 15 40
			rm -rf /tmp/vmcreateoutput.tmp.$$
			;;
		1)
			;;
		esac
		fi
		;;
	2)
		echo "dialog --title \"VirtualBox Control - Select VM to Modify\" --menu \"Choose One\" 18 50 10 \\" >> /tmp/vboxlist.tmp.$$
		VBoxManage -q list vms | while read line
               	do
                  tmp=${line#*\"}
                  vmname=${tmp%\"*}
                  echo "\"$vmname\" \"$vmname\" \\" >> /tmp/vboxlist.tmp.$$
                done
		echo "2>/tmp/vmchoice.tmp.$$" >> /tmp/vboxlist.tmp.$$
		/bin/sh /tmp/vboxlist.tmp.$$
		vmchoice=`cat /tmp/vmchoice.tmp.$$`
		rm -rf /tmp/vboxlist.tmp.$$
		cat /tmp/vmchoice.tmp.$$
		rm -rf /tmp/vmchoice.tmp.$$
		;;
	3)
		echo "dialog --title \"VirtualBox Control - Select VM to Modify\" --menu \"Choose One\" 18 50 10 \\" >> /tmp/vboxlist.tmp.$$
                VBoxManage -q list vms | while read line
                do
                  tmp=${line#*\"}
                  vmname=${tmp%\"*}
                  echo "\"$vmname\" \"$vmname\" \\" >> /tmp/vboxlist.tmp.$$
                done
                echo "2>/tmp/vmchoice.tmp.$$" >> /tmp/vboxlist.tmp.$$
                /bin/sh /tmp/vboxlist.tmp.$$
                vmchoice=`cat /tmp/vmchoice.tmp.$$`
                rm -rf /tmp/vboxlist.tmp.$$
                rm -rf /tmp/vmchoice.tmp.$$
		dialog --title "VirtualBox Control - Select VM to Modify" --menu "Choose One" 18 50 10 \
                "1" "Unmount CD/DVD/ISO" \
                "2" "Mount CD/DVD/ISO" 2>/tmp/vmmount.tmp.$$
		vmmount=`cat /tmp/vmmount.tmp.$$`
		case $vmmount in
		1)
			VBoxManage -q storageattach "$vmchoice" --storagectl "IDE Controller" --port 1 --device 0 --type dvddrive --medium none
		;;
		2)
			userinput "VirtualBox Control - Enter Path to CD/DVD Image" "Enter the path with out escape characters." "/datapool/public/programs/Images"
			VBoxManage -q storageattach "$vmchoice" --storagectl "IDE Controller" --port 1 --device 0 --type dvddrive --medium "$input"
		;;
		esac
                ;;
	4)
                echo "dialog --title \"VirtualBox Control - Select VM to Modify\" --menu \"Choose One\" 18 50 10 \\" >> /tmp/vboxlist.tmp.$$
                VBoxManage -q list vms | while read line
                do
                  tmp=${line#*\"}
                  vmname=${tmp%\"*}
		  state=`VBoxManage showvminfo $vmname | grep State`
              	  tmp=${state#*\:}
                  state=${tmp%\(*}
		  state=`echo "$state" | tr -s " "`
                  echo "\"$vmname\" \"$state\" \\" >> /tmp/vboxlist.tmp.$$
                done
                echo "2>/tmp/vmchoice.tmp.$$" >> /tmp/vboxlist.tmp.$$
                /bin/sh /tmp/vboxlist.tmp.$$
                vmchoice=`cat /tmp/vmchoice.tmp.$$`
                rm -rf /tmp/vboxlist.tmp.$$
                cat /tmp/vmchoice.tmp.$$
                rm -rf /tmp/vmchoice.tmp.$$
		if [ -n "$vmchoice" ]; then
		
		dialog --title "VirtualBox Control - Select VM to Modify" --menu "Choose One" 18 50 10 \
		"start" "start" \
		"pause" "pause" \
		"resume" "resume" \
		"reset" "reset" \
		"poweroff" "poweroff" \
		"savestate" "savestate" \
                "acpipowerbutton" "acpipowerbutton" \
		"acpisleepbutton" "acisleepbutton" 2>/tmp/vmstate.tmp.$$
		vmstate=`cat /tmp/vmstate.tmp.$$`
		rm -rf /tmp/vmstate.tmp.$$
		if [ -n $vmstate ]; then
		if [ $vmstate = "start" ]; then
		userinput "VirtualBox Control - VNC Port" "Enter a port for VNC" "5900"
		if [ -n $input ]; then
		nohup VBoxHeadless -s "$vmchoice" -n -m $input > /dev/null 2>&1 &
		fi
		fi
		VBoxManage controlvm $vmchoice $vmstate
		fi
		fi
                ;;
	5)
                echo "dialog --title \"VirtualBox Control - Select VM to Modify\" --menu \"Choose One\" 18 50 10 \\" >> /tmp/vboxlist.tmp.$$
                VBoxManage -q list vms | while read line
                do
                  tmp=${line#*\"}
                  vmname=${tmp%\"*}
                  echo "\"$vmname\" \"$vmname\" \\" >> /tmp/vboxlist.tmp.$$
                done
                echo "2>/tmp/vmchoice.tmp.$$" >> /tmp/vboxlist.tmp.$$
                /bin/sh /tmp/vboxlist.tmp.$$
                vmchoice=`cat /tmp/vmchoice.tmp.$$`
                rm -rf /tmp/vboxlist.tmp.$$
                cat /tmp/vmchoice.tmp.$$
                rm -rf /tmp/vmchoice.tmp.$$
		
		if [ -n "$vmchoice" ]; then
		
		VBoxManage -q controlvm "$vmchoice" poweroff > /dev/null
		VBoxManage -q storageattach "$vmchoice" --storagectl "IDE Controller" --port 0 --device 0 --medium none > /dev/null
		VBoxManage -q storageattach "$vmchoice" --storagectl "IDE Controller" --port 1 --device 0 --medium none > /dev/null
		VBoxManage -q unregisterimage disk "/datapool/virtualbox/harddrives/$vmchoice.vdi" > /dev/null
		VBoxManage -q unregistervm "$vmchoice" --delete
		rm -f "/datapool/virtualbox/harddrives/$vmchoice.vdi"
		read NAME
		fi
                ;;
	esac done
