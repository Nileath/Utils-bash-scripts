#!/bin/bash

set -o errexit

# Colors
greenColor="\e[0;32m\033[1m"
endColor="\033[0m\e[0m"
redColor="\e[0;31m\033[1m"
blueColor="\e[0;34m\033[1m"
yellowColor="\e[0;33m\033[1m"
purpleColor="\e[0;35m\033[1m"
turquoiseColor="\e[0;36m\033[1m"
grayColor="\e[0;37m\033[1m"

function ctrl_c() {
  tput cnorm
  echo -e "\n\n${redColor}[!] Saliendo...\n${endColor}"
  exit 1
}

# Ctrl + C
trap ctrl_c INT

# Functions
helpPanel() {
  echo -e "\n${yellowColor}[+]${endColor} ${grayColor}Uso: ${purpleColor}${0}${endColor}\n${endColor}"
  echo -e "\t${blueColor}-i)${endColor} ${grayColor}IP actual a calcular${endColor}"
  echo -e "\t${blueColor}-c)${endColor} ${grayColor}CIDR${endColor}"
  echo -e "\t${blueColor}-m)${endColor} ${grayColor}Máscara de red${endColor}"
  echo -e "\n${yellowColor}[!]${endColor} ${grayColor}Se debe indicar un CIDR o una máscara para generar el calculo${endColor}"
}

## Calculate addr to binary
addDotsInBinaries() {
  local binary=$1
  local parsedBinary=""

  for (( i = 0; i < ${#binary}; i += 8 )); do
    bytes="${binary:i:8}"
    parsedBinary="${parsedBinary}${bytes}."
  done

  echo "${parsedBinary%?}"
}

binaryToAddress() {
  local bytes=$(echo $1 | tr "." "\n")
  local parsedIp=""

  for byte in $bytes; do
    let decimal=$(echo -e "ibase=2;$byte" | bc)
    parsedIp+="${decimal}."
  done

  echo "${parsedIp%?}"
}

addressToBinary() {
  local bytes=$(echo $1 | tr "." "\n")
  local binaryIp=""

  for byte in $bytes; do
    binary=$(echo -e "obase=2;$byte" | bc)

    if [ "${#binary}" -lt 8 ]; then
      local necesaryToComplete=$(( 8 - ${#binary} ))
      local range=$(seq 1 $necesaryToComplete)

      binaryIp+="$(for i in $range; do echo -n "0"; done)${binary}."
    else
      binaryIp+="${binary}."
    fi
  done

  echo "${binaryIp%?}"
}

CIDRToMaskIP() {
  local cidr=$1
  local mask=""
  local binaryMask=""
  local OnesRange=$(seq 1 $cidr)
  local ZerosRange=$(seq 1 $((32 - $cidr)))

  mask+=$(for i in $OnesRange; do echo -n "1"; done)
  mask+=$(for i in $ZerosRange; do echo -n "0"; done)

  echo $(addDotsInBinaries $mask)
}

getBinaryMask() {
  type=$1
  mask=$2

  if [ "$type" == "MASK" ]; then
    echo $(addressToBinary $mask)
  else
    echo $(CIDRToMaskIP $mask)
  fi
}

calculatNetworkId() {
  local binaryIp=$(echo $1 | tr -d '.')
  local binaryMask=$(echo $2 | tr -d '.')

  local binaryNetworkId=""
  for (( i = 0; i < 32; i += 1 )); do
    local ipBit="${binaryIp:i:1}"
    local maskBit="${binaryMask:i:1}"

    if [ "$ipBit" == "$maskBit" ] && [ "$ipBit" == "1" ]; then
      binaryNetworkId+="1"
    else
      binaryNetworkId+="0"
    fi
  done

  echo $(addDotsInBinaries $binaryNetworkId)
}

calculateBroadcast() {
  local networkId=$(echo $1 | tr -d '.')
  local cidr=$2

  local bitsToModify=$((32 - $cidr))
  local broadcast="${networkId:0:$(( 32 - $bitsToModify ))}"

  broadcast+=$(for i in $(seq 1 $bitsToModify); do echo -n "1"; done)

  echo $(addDotsInBinaries $broadcast)
}

getSubnetInfo() {
  local ip=$1
  local mask=$2
  local type=$3

  local binaryIp=$(addressToBinary $ip)
  local binaryMask=$(getBinaryMask $type $mask)
  local binaryNetworkId=$(calculatNetworkId $binaryIp $binaryMask)
  local cidr=$(echo -n $binaryMask | tr -cd "1" | wc -c)
  local binaryBroadcast=$(calculateBroadcast $binaryNetworkId $cidr)

  local parsedIp=$(binaryToAddress $binaryIp)
  local parsedMask=$(binaryToAddress $binaryMask)
  local parsedNetworkId=$(binaryToAddress $binaryNetworkId)
  local parsedBroadcast=$(binaryToAddress $binaryBroadcast)

  echo -e "${yellowColor}[+]${endColor} ${grayColor}IP (${endColor}${blueColor}${parsedIp}${endColor}${grayColor}) - [${endColor}${purpleColor}${binaryIp}${endColor}${grayColor}]${endColor}"
  echo -e "${yellowColor}[+]${endColor} ${grayColor}CIDR ${blueColor}/${cidr}${endColor}"
  echo -e "${yellowColor}[+]${endColor} ${grayColor}MASK (${endColor}${blueColor}${parsedMask}${endColor}${grayColor}) - [${endColor}${purpleColor}${binaryMask}${endColor}${grayColor}]${endColor}"


  echo -e "${yellowColor}[+]${endColor} ${grayColor}NETWORK ID (${endColor}${blueColor}${parsedNetworkId}${endColor}${grayColor}) - [${endColor}${purpleColor}${binaryNetworkId}${endColor}${grayColor}]${endColor}"
  echo -e "${yellowColor}[+]${endColor} ${grayColor}BROADCAST (${endColor}${blueColor}${parsedBroadcast}${endColor}${grayColor}) - [${endColor}${purpleColor}${binaryBroadcast}${endColor}${grayColor}]${endColor}"
}

# Main
tput civis

while getopts "i:c:m:h" args; do
  case $args in
    i) ip=$OPTARG;;
    c) cidr=$OPTARG;;
    m) mask=$OPTARG;;
    h) ;;
  esac
done

if [ $ip ] && [ $cidr ]; then
  getSubnetInfo $ip $cidr "CIDR"
elif [ $ip ] && [ $mask ]; then
  getSubnetInfo $ip $mask "MASK"
else
  helpPanel
fi

tput cnorm
