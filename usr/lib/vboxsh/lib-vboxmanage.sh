#!/bin/bash
###### vboxsh VirtualBox Management Library ######

vbox_list_vms ()
{
vm_longlist=$(VBoxManage list vms --long)
vm_list=""
for name in $(grep "Name: " <<$vm_list | sed s/^Name:[\s+]//g) 
do
    for state in $(grep "State: " <<$vm_list | sed s/^State:[\s+]//g) 
    do
        vm_list="$vmlist\"$name\" \"$state\"" 
    done
done



echo $vm_list >> /tmp/vm-manage.log
exit
}
