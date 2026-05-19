#!/bin/bash

ssh-keygen -t ed25519
# entrez wapt comme nom de clé
# tapez deux fois sur entrée lors de la demande de la passphrase

scp ~/.ssh/wapt.pub Administrateur@192.220.19.38:C:/Users/Administrateur/

ssh-agent /bin/bash
ssh-add /home/wapt/.ssh/wapt


# côté serveur windows : 
