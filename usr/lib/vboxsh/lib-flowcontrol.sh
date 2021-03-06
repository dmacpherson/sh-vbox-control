#!/bin/bash

usage ()
{
	msg="vboxsh -[idlh]
    -i <dia/cli>         Override interface type default=dia
    -d                   Explicitly enable debugging (/var/log/vboxsh/debug.log)
    -l                   Explicitly enable logging to file
                         ($LOGFILE)
    -h                   Help: show usage\n"

	echo -e "$msg"
}




# $1 worker/program name
# $2... extra args for worker/program (optional)
execute ()
{
	[ -z "$1" ] && debug 'MAIN' "execute $@" && die_error "Use the execute function like this: execute <name>"
	PWD_BACKUP=`pwd`
	object=$1

	log "*** Executing worker $1"
	if type -t $object | grep -q function
		then
			shift 2
			$object "$@"
			local ret=$?
			exit_var=exit_$object
			read $exit_var <<< $ret # maintain exit status of each worker
		else
			die_error "$object is not defined!"
	fi
	
	debug 'MAIN' "Execute(): $object exit state was $ret"
	cd $PWD_BACKUP
	return $ret
}


check_depend_dialog ()
{
   check_cdialog=$(cdialog --help | grep -i "version")
   if [ -z "$check_cdialog" ]
   then
      check_dialog=$(dialog --help | grep -i "cdialog")
      if [ -n "$check_dialog" ]
      then
         DIACMD="dialog"
      else
         UI="cli"
      fi
   else
      DIACMD="cdialog"
   fi

}


# $1 exit code (optional)
exit_vboxsh ()
{
	log "-------------- EXITING --------------"
	cleanup_runtime
	[ "$var_UI_TYPE" = dia ] && clear
	exit $1
}
