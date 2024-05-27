#!/bin/bash

# The first argument to the script is accessed with $1
firmware=$1

MAINTENANCE_SEM_NAME="/tmp/coolbox_maintenance"

stop_listner(){
  local screens=(`screen -ls coolbox | grep -Po "\K[0-9]+(?=\.coolbox)" | sort --unique`)
  for pid in "${screens[@]}"; do
    timeout 1 screen -S $pid.coolbox -X quit
  done

  #removing listner output
  rm -f $CLI_OUTPUT
#  rm -f ${CLI_OUTPUT}_50
}

firmware_update(){
	# Check if pip is installed
	if ! command -v pip &> /dev/null
	then
		echo "$(date +"%Y-%m-%d %T") pip could not be found, installing..."
		apt update > /dev/null
		apt install python-pip -y > /dev/null
	else
		echo "$(date +"%Y-%m-%d %T") pip is already installed."
	fi

	# Check if esptool is installed
	if pip show esptool &> /dev/null
	then
		echo "$(date +"%Y-%m-%d %T") esptool is already installed."
	else
		echo "$(date +"%Y-%m-%d %T") esptool could not be found, installing..."
		pip install esptool > /dev/null
	fi
	echo "$(date +"%Y-%m-%d %T") Patching coolbox script for maintenance window..."
	sed -i '46s/  if \[\[ a -le 60 \]\]; then/  if \[\[ a -le 600 \]\]; then/' /hive/opt/coolbox/coolbox
	echo "$(date +"%Y-%m-%d %T") - update firmware" > $MAINTENANCE_SEM_NAME

	stop_listner

	echo "$(date +"%Y-%m-%d %T") Stopping miner"

	miner stop

	sleep 10
        echo "$(date +"%Y-%m-%d %T") Erasing flash, please wait it will take about 60 seconds..."


        t_error_txt=`esptool.py --chip esp32 --port /dev/ttyUSB0 erase_flash 2>&1`

        # Check if esptool.py command is successful
        if [[ $? -ne 0 ]]; then
                  #exit_code=5
                  echo "$(date +"%Y-%m-%d %T") ${RED}Error erasing flash ${NOCOLOR}: $t_error_txt"
        else
                  echo "$(date +"%Y-%m-%d %T") ${GREEN}Erasing flash Sucessfull"
	          sleep 2
		  echo "$(date +"%Y-%m-%d %T") flashing firmware, this can take upto a 60 seconds..."
		  t1_error_txt=`esptool.py --chip esp32 --port /dev/ttyUSB0 write_flash -z 0x0 $firmware 2>&1`
		  # Check if esptool.py command is successful
		  if [[ $? -ne 0 ]]; then
			  #exit_code=5
			  echo "$(date +"%Y-%m-%d %T") ${RED}Error on flashing firmware ${NOCOLOR}: $t1_error_txt"
		  else
	  		  echo "$(date +"%Y-%m-%d %T") ${GREEN}flashing firmware Sucessfull"
		  fi
		  sleep 2

        fi
	echo "$(date +"%Y-%m-%d %T") Taking CoolboXX II out of maintenance mode"
	rm -f ${MAINTENANCE_SEM_NAME}
	echo "$(date +"%Y-%m-%d %T") Reverting coolbox script changes"
	sed -i '46s/  if \[\[ a -le 600 \]\]; then/  if \[\[ a -le 60 \]\]; then/' /hive/opt/coolbox/coolbox

	echo "$(date +"%Y-%m-%d %T") Starting miner"
	miner start
	sleep 3
}

# Call the function with the argument
firmware_update
echo "$(date +"%Y-%m-%d %T") Running Fancheck..."
/hive/opt/coolbox/coolbox --fan_check
echo "$(date +"%Y-%m-%d %T") -----Firmware Update process completed!!-----"

