#!/bin/bash
###### vboxsh VirtualBox Management Library ######

vbox_list_vms ()
{
vm_longlist=$(VBoxManage list vms --long)
vm_list=""
for name in $(grep "Name: " | sed s/^Name:[\s+]//g <<$vm_list) 
do
    for state in $(grep "State: " | sed s/^State:[\s+]//g <<$vm_list) 
    do
        vm_list="$vmlist\"$name\" \"$state\"" 
    done
done



echo $vm_list >> /tmp/vm-manage.log
exit
}
