#!/bin/bash

# /etc/default/grub


sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="quiet"/GRUB_CMDLINE_LINUX_DEFAULT="quiet iommu=force l1tf=off page_poison=on pti=on slab_nomerge=yes slub_debug=FZP spec_store_bypass_disable=seccomp spectre_v2=on page_alloc.shuffle=1 mds=full"/g' /etc/default/grub
update-grub



