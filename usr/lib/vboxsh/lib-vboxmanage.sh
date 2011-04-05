#!/bin/bash
###### vboxsh VirtualBox Management Library ######

vbox_list_vms ()
{
vm_list=""
VBoxManage list vms --long > $TMPDIR/vmlist.tmp

for name in $(cat $TMPDIR/vmlist.tmp | grep "Name: " | sed s/^Name:[\s+]//g) 
do
    #for state in $(cat $TMPDIR/vmlist.tmp | grep "State: " | sed s/^State:[\s+]//g) 
    #do
    #    vm_list="$vmlist\"$name\" \"$state\"" 
    #done
    echo $name >> $TMPDIR/name.log
done



echo $vm_list >> /tmp/vm-manage.log
exit
}
