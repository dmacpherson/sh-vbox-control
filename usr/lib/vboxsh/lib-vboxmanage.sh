#!/bin/bash
###### vboxsh VirtualBox Management Library ######

vbox_list_vms ()
{
VBoxManage list vms --long > $TMPDIR/vmlist.tmp

for name in $(cat $TMPDIR/vmlist.tmp | grep "Name: " | sed s/^Name:[\s+]//g) 
do
    for state in $(cat $TMPDIR/vmlist.tmp | grep "State: " <<$vm_list | sed s/^State:[\s+]//g) 
    do
        vm_list="$vmlist\"$name\" \"$state\"" 
    done
done



echo $vm_list >> /tmp/vm-manage.log
exit
}
