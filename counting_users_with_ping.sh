#! /bin/bash

#----------------------------------------------------------------------------------------------------------------------------------------------------------
#
# Filename : counting_users_with_ping.sh
# Description: A bash script for outputting the number of active devices on a network to a file.
# Author: Alexandros Dorodoulis
# Requirements: ping
#
#----------------------------------------------------------------------------------------------------------------------------------------------------------

function find_limit_and_fourth_octave(){
  possibleIps=$1
  limit=$possibleIps
  while [[ $fourthOctave -gt $limit ]]; do
    limit=$(($limit+$possibleIps))
  done
  fourthOctave=$(($limit-$possibleIps-1))
}

if (( $# == 1))
  outputDirectory=$1
else
  outputDirectory="/var/www/html" # Change this directory in order to change where the script outputs the files
fi
filename="hackers.txt" # The name of the outputted file
emptyIpsBeforeQuiting=6 # How many IPs in a row can be unasigned before stoping the scan.
numberOfHackers=0 # Initialize number of hackers.
alwaysActiveDevices=2 # Number of always active devices.

networksIp=$(ip addr | grep 'state UP' -A2 | tail -n1 | awk '{print $2}') # Find the ip and the subnetwork.
subnetwork=$(echo $networksIp| awk -F/ '{print $2}') # Get networks bit-length of the prefix.
fourthOctave=$(echo $networksIp| awk -F. '{print $4}' | awk -F/ '{print $1}') # Find the 4th octave of the ip.
networksIp=$(echo $networksIp | awk -F. '{OFS="."; $4="" ;print $0}') # Delete the 4th ip octave.
temp=0 # Initialize temp

# Find which range of IPs should scan base on subnetwork.
case $subnetwork in
  24)
    limit=254
    fourthOctave=0
    ;;
  25)
    find_limit_and_fourth_octave 126
    ;;
  26)
    find_limit_and_fourth_octave 62
    ;;
  27)
    find_limit_and_fourth_octave 30
    ;;
  28)
    find_limit_and_fourth_octave 14
    ;;
  29)
    find_limit_and_fourth_octave 6
    ;;
  30)
    find_limit_and_fourth_octave 2
    ;;
esac

# Ping devices on the network and count the active ones.
while [[ $fourthOctave -le $limit && $temp -le $emptyIpsBeforeQuiting ]] ;do
  temp=$(($temp+1))
  ping -c 1 $networksIp$fourthOctave &> /dev/null
  if [[ $? -eq 0 ]]; then
    numberOfHackers=$(($numberOfHackers+1))
    temp=0
  fi
  fourthOctave=$(($fourthOctave+1))
done

# Check if the directory exists, if it doesn't create it.
if [[ ! -d $outputDirectory ]]; then
  mkdir -p $outputDirectory
fi
echo $(($numberOfHackers-$alwaysActiveDevices)) > $outputDirectory/$fileName # Output the number of active devices.
