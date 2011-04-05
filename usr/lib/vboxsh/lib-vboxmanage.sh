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

# Generate list of OS types for VM Creation
# List up to date as of VirtualBox 4
# Marking 'gen_os_type' Deprecated --OF
gen_os_type ()
{
ask_option 0 
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
                "QNX" "QNX"
}


### Queuery ostypes known to the version of virtualbox installed
queuery_vbox_ostypes()
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

