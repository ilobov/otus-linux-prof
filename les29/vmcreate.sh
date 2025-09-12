vboxmanage createvm --name "pxetest" --ostype Ubuntu24_LTS_64 --register
vboxmanage modifyvm pxetest --description "PXEboot test" --memory 6144 --cpus 2 --boot1 disk --boot2 net --nic1 intnet --intnet1 pxenet
# --macaddress1 080027fbad17
vboxmanage createmedium disk --filename pxeboot-disk.vdi --size 20000
vboxmanage storagectl pxetest --name "SATA" --add sata --bootable on
vboxmanage storageattach pxetest --storagectl "SATA" --port 1 --type hdd --medium pxeboot-disk.vdi
vboxmanage startvm pxetest