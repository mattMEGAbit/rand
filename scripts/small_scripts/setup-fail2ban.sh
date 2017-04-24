#!/bin/bash

# setup-install-fail2ban.sh


sudo apt-get install fail2ban

sudo service fail2ban stop

sudo awk '{ printf "# "; print; }' /etc/fail2ban/jail.conf | sudo tee /etc/fail2ban/jail.local

sudo apt-get install nginx sendmail iptables-persistent

# each one of these is a setting

sudo iptables -A INPUT -i lo -j ACCEPT
sudo iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT
sudo iptables -A INPUT -p tcp -m multiport --dports 80,443 -j ACCEPT
sudo iptables -A INPUT -j DROP

sudo dpkg-reconfigure iptables-persistent

sudo service fail2ban start

sudo iptables -S

# config file
# sudo nano /etc/fail2ban/jail.local

