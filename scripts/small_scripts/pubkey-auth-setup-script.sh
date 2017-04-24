#!/bin/bash

# setup ssh with key-based auth - dont premit root login
# makes changes to the SSH daemon's configuration file
# /etc/ssh/sshd_config
# dont run this until 
# you have setup a different user with sudo privs 
# and uploaded their pubkeys

sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config

sed -i 's/PubkeyAuthentication no/PubkeyAuthentication yes/g' /etc/ssh/sshd_config

sed -i 's/UsePAM yes/UsePAM no/g' /etc/ssh/sshd_config

sed -i 's/ChallengeResponseAuthentication yes/ChallengeResponseAuthentication no/g' /etc/ssh/sshd_config

sed -i 's/PermitRootLogin yes/PermitRootLogin no/g' /etc/ssh/sshd_config

# only listen on ipv4

echo 'AddressFamily inet' | sudo tee -a /etc/ssh/sshd_config

systemctl reload ssh

