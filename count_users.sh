#! /bin/bash

#----------------------------------------------------------------------------------------------------------------------------------------------------------
#
# Filename : counting_users.sh
# Description: Shell script for publishing network's daily number of unique mac addresses and the number of active devices to two MQTT paths.
# Author: Alexandros Dorodoulis
# Requirements: nmap, mosquitto_pub
#
#----------------------------------------------------------------------------------------------------------------------------------------------------------

function usage(){
  echo "Possible arguments:
          -fn or --filename         define filename
          -a or --active            define the number of always active devices on the network (routers etc.)"
}

alwaysActiveDevices=2 # Number of always active devices.
fileName="hackers.txt" # The name of the outputted file
currentDirectory=$(pwd)

#Read the numer of active devices that th
if [[ -e $currentDirectory$fileName ]]; then
  read previousActiveDevices < $currentDirectory/$fileName.txt
else
  previousActiveDevices=999999999
fi

# Parse parameters
while [[ $# > 0 ]]
  do
  key="$1"
  case $key in
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

networksIp=$(ip addr | grep 'state UP' -A2 | tail -n1 | awk '{print $2}') # Find the ip and the subnetwork that nmap should scan.
subnetwork=$(echo $networksIp| awk -F/ '{print $2}') # Get network's number of mask bits.
networksIp=$(echo $networksIp | awk -F. '{OFS="."; $4='0'; print $0}')/$subnetwork # Replace the 4th ip octave with 0.
sudo nmap -sP $networksIp --disable-arp-ping | grep ..:..:..:..:..:.. | awk '{print $3}' > $currentDirectory/mac_addresses.txt # Write mac addresses to mac_addresses.txt
activeDevices=$(wc -l < $currentDirectory/mac_addresses.txt) # Count the active devices
actualDevices=$(($activeDevices-$alwaysActiveDevices)) # The actual number of active devices

# If the device count returns 0 active devices check again
# If not and the number of activeDevices is different
if [[ $actualDevices -le 0 ]]; then
  $currentDirectory/count_users_with_ping.sh -fn $fileName -a $alwaysActiveDevice -fc $actualDevices
elif [[ $activeDevices -ne $previousActiveDevices ]]; then
  mosquitto_pub -h www.techministry.gr -u EnterYourUsernameHere -P aSuperSecurePassword --cafile PathToYourCA -t "techministry/spacestatus/hackers" -m "$actualDevices" # Publish the number of active users through MQTT
  echo $actualDevices > $currentDirectory/$fileName
fi
