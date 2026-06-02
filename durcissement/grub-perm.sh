#!/bin/bash

# les options de démarrage présente ici permettent d'améliorer la sécurité globale.
sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="quiet"/GRUB_CMDLINE_LINUX_DEFAULT="quiet iommu=force \
l1tf=off page_poison=on pti=on slab_nomerge=yes slub_debug=FZP spec_store_bypass_disable=seccomp \
spectre_v2=on page_alloc.shuffle=1 mds=full"/g' /etc/default/grub

#on met à jour le grub
update-grub

# une fois le grub mis à jour il faut effecteur un redemmarage afin que les options 
# qui y sont liés prennent effets.

find / -type f \( -nouser -o -nogroup \) -ls 2> /dev/null

find / -type d \( -perm -0002 -a \! -perm -1000 \) -ls 2> /dev/null

find / -type d -perm -0002 -a \! -uid 0 -ls 2> /dev/null

find / -type f -perm -0002 -ls 2> /dev/null | grep -v 'proc' | grep -v 'sys'

find / -type f -perm /6000 -ls 2> /dev/null
# retirer le sticky bit au cas par cas




