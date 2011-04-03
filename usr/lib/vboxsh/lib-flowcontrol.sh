#!/bin/bash

usage ()
{
	msg="aif -p <procedurename>  Select a procedure # If given, this *must* be the first option
    -i <dia/cli>         Override interface type (optional)
    -d                   Explicitly enable debugging (/var/log/aif/debug.log) (optional)
    -l                   Explicitly enable logging to file (/var/log/aif/aif.log) (optional)
    -h                   Help: show usage  (optional)\n"

	echo -e "$msg"
}


# $1 library name   

load_lib ()
{
	[ -z "$1" ] && die_error "load_library needs a library as \$1"
	log "Loading library /libs/$1 ..."
	lib=$LIB_USER/"$1"
	
	source $lib || die_error "Something went wrong while sourcing library $lib"
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






# use this function to stop the installation procedure.
# $1 exit code (optional)
exit_vboxsh ()
{
	log "-------------- EXITING --------------"
	cleanup_runtime
	[ "$var_UI_TYPE" = dia ] && clear
	exit $1
}
