#!/bin/bash
mkdir -p /home/user/coolboxx && cd /home/user/coolboxx
wget https://github.com/fpovoski/CoolboxxII/raw/main/coolboxx2-factory-V1_0.bin
wget https://github.com/fpovoski/CoolboxxII/raw/main/coolboxx2-firmware.sh
chmod +x ./coolboxx2-firmware.sh
./coolboxx2-firmware.sh ./coolboxx2-factory-V1_0.bin
cd /home/user
rm -rf coolboxx
