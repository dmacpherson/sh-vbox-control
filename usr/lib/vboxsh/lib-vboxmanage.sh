#!/bin/bash
###### vboxsh VirtualBox Management Library ######

vbox_list_vms ()
{
vm_list=$(`VBoxManages list vms | sort | sed 's/[\{\}]/\"/g'`)
echo $vm_list >> $LOG_DIR/vm-manage.log
exit
}
