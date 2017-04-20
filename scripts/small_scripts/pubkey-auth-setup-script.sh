#!/bin/bash

sed -i 's/PasswordAuthentication  yes/PasswordAuthentication no/g' /etc/ssh/sshd_config

sed -i 's/PubkeyAuthentication no/PubkeyAuthentication yes/g' /etc/ssh/sshd_config

sed -i 's/UsePAM yes/ UsePAM no/g' /etc/ssh/sshd_config

# PermitRootLogin without-password - up to you..

systemctl reload ssh
