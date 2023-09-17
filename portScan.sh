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

function checkPort() {
  ip=$1
  port=$2

  # echo -e "Scaning port $port"

  (exec 3<> /dev/tcp/${ip}/${port}) 2>/dev/null

  if [ $? -eq 0 ]; then
    echo -e "[+] Host $ip - Port $port (OPEN)"
  fi

  exec 3<&-
  exec 3>&-
}

# Main
declare -a ports=( $(seq 1 65535) )

if [ ! $1 ]; then
  echo -e "\n[!] Uso: $0 <ip_address>\n"
  exit 1
fi


tput civis
ip="$1"

for port in ${ports[@]}; do
  checkPort $ip $port &
done

wait

tput cnorm
