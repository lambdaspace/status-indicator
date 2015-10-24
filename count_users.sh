#! /bin/bash

#----------------------------------------------------------------------------------------------------------------------------------------------------------
#
# Filename : counting_users.sh
# Description: A bash script for outputting network's active mac addresses and the number of active devices to two files.
# Author: Alexandros Dorodoulis
# Requirements: nmap
#
#----------------------------------------------------------------------------------------------------------------------------------------------------------

function usage(){
  echo "Possible arguments:
          -d or --directory         define output directory
          -fn or --filename         define filename
          -a or --active            define the number of always active devices on the network (routers etc.)"
}

alwaysActiveDevices=2 # Number of always active devices.
outputDirectory="/var/www/html" # Change this directory in order to change where the script outputs the files
fileName="hackers.txt" # The name of the outputted file
scriptDirectory=$(pwd)

# Parse parameters
while [[ $# > 0 ]]
  do
  key="$1"
  case $key in
      -d|--directory)
        outputDirectory="$2"
        shift
      ;;
      -fn|--filenames)
        fileName="$2"
        shift
      ;;
      -a|--active)
        alwaysActiveDevices="$2"
        shift
      ;;
      -h|--help)
        usage
        exit 1
      ;;
    esac
  shift
done

# Check if the directory exists, if it doesn't create it.
if [[ ! -d $outputDirectory ]]; then
  mkdir -p $outputDirectory
fi

networksIp=$(ip addr | grep 'state UP' -A2 | tail -n1 | awk '{print $2}') # Find the ip and the subnetwork that nmap should scan.
subnetwork=$(echo $networksIp| awk -F/ '{print $2}') # Get network's number of mask bits.
networksIp=$(echo $networksIp | awk -F. '{OFS="."; $4='0'; print $0}')/$subnetwork # Replace the 4th ip octave with 0.
sudo nmap -sP $networksIp | grep ..:..:..:..:..:.. | awk '{print $3}' > $outputDirectory/mac_addresses.txt # Write mac addresses to mac_addresses.txt
activeDevices=$(wc -l < $outputDirectory/mac_addresses.txt) # Count the active devices
actualDevices=$(($activeDevices-$alwaysActiveDevices)) # The actual number of active devices

if [[ $actualDevices -le 0 ]]; then
  $($scriptDirectory/count_users_with_ping.sh -d $outputDirectory -fn $fileName -a $alwaysActiveDevices -fc $actualDevices)
else
  echo $actualDevices > $outputDirectory/$fileName # Output the number of active users to hackers.txt
fi
