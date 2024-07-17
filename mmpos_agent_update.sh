
#!/bin/bash
sudo su -
cd /opt/mmp/bin
agent-stop && wget https://update.mmpos.eu/fixes/c/agent -O agent && agent-start

