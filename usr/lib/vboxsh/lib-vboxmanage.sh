#!/bin/bash
###### vboxsh VirtualBox Management Library ######
touch $
vbox_list_vms ()
{
vm_list=$(`VBoxManager list vms | sort | sed 's/[\{\}]/\"/g'`)
echo $vm_list >> /tmp/vm-manage.log
exit
}
