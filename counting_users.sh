#! /bin/bash

#----------------------------------------------------------------------------------------------------------------------------------------------------------
#
# Filename : counting_users.sh
# Description: A bash script for outputting network's active mac addresses and the number of active devices to two files.
# Author: Alexandros Dorodoulis
# Requirements: nmap
#
#----------------------------------------------------------------------------------------------------------------------------------------------------------
alwaysActiveDevices=2
outputDirectory="/var/www/html" # Change this directory in order to change where the script outputs the files
if [[ ! -d $outputDirectory ]]; then
  mkdir -p $outputDirectory
fi
networksIp=$(ip addr | grep 'state UP' -A2 | tail -n1 | awk '{print $2}') # Find the ip and the subnetwork that nmap should scan.
subnetwork=$(echo $networksIp| awk -F/ '{print $2}') # Get networks bit-length of the prefix.
networksIp=$(echo $networksIp | awk -F. '{OFS="."; $4='0'; print $0}')/$subnetwork # Replace the 4th ip octave with 0.
sudo nmap -sP $networksIp | grep ..:..:..:..:..:.. | awk '{print $3}' > $outputDirectory/mac_addresses.txt # Write mac addresses to mac_addresses.txt
activeDevices=$(wc -l < $outputDirectory/mac_addresses.txt) # Count the active devices
echo $(($activeDevices-$alwaysActiveDevices))> $outputDirectory/hackers.txt # Output the number of active users to hackers.txt
