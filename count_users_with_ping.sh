#! /bin/bash

#----------------------------------------------------------------------------------------------------------------------------------------------------------
#
# Filename : counting_users_with_ping.sh
# Description: A shell script for counting and publishing through MQTT the number of active devices on the local network.
# Author: Alexandros Dorodoulis
# Requirements: ping, mosquitto_pub
#
#----------------------------------------------------------------------------------------------------------------------------------------------------------

logDirectory="/var/log/count_users" # The directory where the error logs will be outputted
fileName="hackers.txt" # The name of the outputted file
emptyIpsBeforeQuiting=18 # How many IPs in a row can be unassigned before stopping the scan.
activeDevices=0 # Initialize number of active devices.
alwaysActiveDevices=2 # Number of always active devices.
currentDirectory=$(pwd)


# Find the range that the script should scan based on the number of mask bits and the host's ip
function find_limit_and_fourth_octave(){
  possibleIps=$1
  limit=$possibleIps
  while [[ $fourthOctave -gt $limit ]]; do
    limit=$(($limit+$possibleIps))
  done
  fourthOctave=$(($limit-$possibleIps-1))
}

# Create error log
function log(){
    if [[ ! -d $logDirectory ]]; then
      mkdir -p $logDirectory
    fi
    now=$(date +'%d/%m/%Y %T')
    echo $now "call script number:" $previousScriptNumber "this script results:" $actualDevices >> $logDirectory/error.logs
}

function usage(){
  echo "Possible arguments:
          -fn or --filename         define filename
          -a or --active            define the number of always active devices on the network (routers etc.)
          -fc or --fallback_call    define the number of connected devices if you already have a number and you want to check it to be sure"
}

# Parse parameters
while [[ $# > 0 ]]
  do
  key="$1"
  case $key in
      -fc|--fallback_call)
        previousScriptNumber="$2"
        shift
      ;;
      -fn|--filename)
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

networksIp=$(ip addr | grep 'state UP' -A2 | tail -n1 | awk '{print $2}') # Find the ip and the subnetwork.
subnetwork=$(echo $networksIp| awk -F/ '{print $2}') # Get network's number of mask bits.
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
while [[ $fourthOctave -le $limit && $temp -le $emptyIpsBeforeQuiting ]]; do
  ping -c 1 -t 1 $networksIp$fourthOctave &> /dev/null
  result=$?
  if [[ $result -eq 0 ]]; then
    activeDevices=$(($activeDevices+1))
    temp=0
  else
    temp=$(($temp+1))
  fi
  fourthOctave=$(($fourthOctave+1))
done

actualDevices=$(($activeDevices-$alwaysActiveDevices))
# Log an error if this script is used as a fall-back script and it counts a different amount of active devices
if [[ -v previousScriptNumber && $actualDevices -ne $previousScriptNumber ]]; then
  log
fi
mosquitto_pub -h www.techministry.gr -u EnterYourUsernameHere -P aSuperSecurePassword --cafile PathToYourCA -t "techministry/spacestatus/hackers" -m "$actualDevices" # Publish the number of active users through MQTT
echo $actualDevices > $currentDirectory/$fileName
