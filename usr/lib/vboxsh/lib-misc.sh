#!/bin/bash


# runs a process and makes sure the output is shown to the user. sets the exit state of the executed program ($<identifier>_exitcode) so the caller can show a concluding message.
# when in dia mode, we will run the program and a dialog instance in the background (cause that's just how it works with dia)
# when in cli mode, the program will just run in the foreground. technically it can be run backgrounded but then we need tail -f (cli_follow_progress), and we miss the beginning of the output if it goes too fast, not to mention because of the sleep in run_background
# $1 identifier
# $2 command (will be eval'ed)
# $3 logfile
# $4 title to show while process is running
run_controlled ()
{
	[ -z "$1" ] && die_error "run_controlled: please specify an identifier to keep track of the command!"
	[ -z "$2" ] && die_error "run_controlled needs a command to execute!"
	[ -z "$3" ] && die_error "run_controlled needs a logfile to redirect output to!"
	[ -z "$4" ] && die_error "run_controlled needs a title to show while your process is running!"
	
	log_parent=$(dirname $3)
	if [ ! -d $log_parent ]; then
		mkdir -p $log_parent || die_error "Could not create $log_parent, we were asked to log $1 to $3"
	fi
	if [ "$var_UI_TYPE" = dia ]
	then
		run_background $1 "$2" $3
		follow_progress " $4 " $3 $BACKGROUND_PID # dia mode ignores the pid. cli uses it to know how long it must do tail -f
		wait_for $1 $FOLLOW_PID
		CONTROLLED_EXIT=$BACKGROUND_EXIT
	else
		notify "$4"
		eval "$2" >>$3 2>&1
		CONTROLLED_EXIT=$?
	fi
}


# run a process in the background, and log it's stdout and stderr to a specific logfile
# returncode is stored in BACKGROUND_EXIT
# pid of the backgrounded wrapper process is stored in BACKGROUND_PID (this is _not_ the pid of $2)
# $1 identifier -> WARNING: do never ever use -'s or other fancy characters here. only numbers, letters and _ please. (because $<identifier>_exitcode must be a valid bash variable!)
# $2 command (will be eval'ed)
# $3 logfile
run_background ()
{
	[ -z "$1" ] && die_error "run_background: please specify an identifier to keep track of the command!"
	[ -z "$2" ] && die_error "run_background needs a command to execute!"
	[ -z "$3" ] && die_error "run_background needs a logfile to redirect output to!"

	log_parent=$(dirname $3)
	if [ ! -d $log_parent ]; then
		mkdir -p $log_parent || die_error "Could not create $log_parent, we were asked to log $1 to $3"
	fi

	debug 'MISC' "run_background called. identifier: $1, command: $2, logfile: $3"
	( \
		touch $TMPDIR/vboxsh-$1-running
		debug 'MISC' "run_background starting $1: $2 >>$3 2>&1"
		[ -f $3 ] && echo -e "\n\n\n" >>$3
		echo "STARTING $1 . Executing $2 >>$3 2>&1\n" >> $3;
		eval "$2" >>$3 2>&1
		BACKGROUND_EXIT=$?
		debug 'MISC' "run_background done with $1: exitcode (\$$1_exitcode): ${!var_exit} .Logfile $3"
		echo >> $3   
		rm -f $TMPDIR/vboxsh-$1-running
	) &
	BACKGROUND_PID=$!

	sleep 2
}


# wait until a process is done
# $1 identifier. WARNING! see above
# $2 pid of a process to kill when done (optional). useful for dialog --no-kill --tailboxbg's pid.
wait_for ()
{
	[ -z "$1" ] && die_error "wait_for needs an identifier to know which command to wait on!"

	while [ -f $TMPDIR/vboxsh-$1-running ]
	do
		sleep 1
	done

	[ -n "$2" ] && kill $2
}


# $1 needle
# $2 set (array) haystack
check_is_in ()
{
	[ -z "$1" ] && die_error "check_is_in needs a non-empty needle as \$1 and a haystack as \$2!(got: check_is_in '$1' '$2'" # haystack can be empty though

	local needle="$1" element
	shift
	for element
	do
		[[ $element = $needle ]] && return 0
	done
	return 1
}


# cleans up file in the runtime directory who can be deleted, make dir first if needed
cleanup_runtime ()
{
	mkdir -p $TMPDIR || die_error "Cannot create $TMPDIR"
	rm -rf $TMPDIR/vboxsh-* &>/dev/null
}

dumpargs() { for i in "$@" ; do echo $i ; done ; }


# OS type list as of VirtualBox 4.0.0
get_os_type ()
{
askoption 0 "Select the Virtual Machines OS type." '' required "0" "Cancel" \
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
                "QNX" "QNX"
}
