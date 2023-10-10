#!/bin/bash

function ctrl_c() {
  tput cnorm
  echo -e "\n\n${redColor}[!] Saliendo...\n${endColor}"
  exit 1
}

# Ctrl + C
trap ctrl_c INT

tput civis
old_process=$(ps -eo user,command)

while true; do
  new_process=$(ps -eo user,command)
  diff <(echo "$old_process") <(echo "$new_process") | grep "[\>\<]" | grep -vE "command|kworker|procmon"
  old_process=$new_process
done

tput cnorm
