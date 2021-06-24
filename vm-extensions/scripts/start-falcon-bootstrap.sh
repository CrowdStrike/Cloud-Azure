#!/bin/bash
exec > logfile 2>&1
set -x
PROCEED=0
for var in $*; do 
   if [[ "$var" == *--client_id=* ]]
   then
      export FALCON_CLIENT_ID="${var/--client_id=/}"
      PROCEED=$((PROCEED + 1))
   fi   
   if [[ "$var" == *--client_secret=* ]]
   then
      export FALCON_CLIENT_SECRET="${var/--client_secret=/}"
      PROCEED=$((PROCEED + 1))      
   fi   
   if [[ "$var" == *--cid=* ]]
   then
      export FALCON_CID="${var/--cid=/}"
      PROCEED=$((PROCEED + 1))      
   fi
   if [[ "$var" == *--falcon_cloud=* ]]
   then
      export FALCON_CLOUD="${var/--falcon_cloud=/}"
   fi
done

if [[ $PROCEED -eq 3 ]]
then
    cd /var/tmp
    wget -O stage1 https://raw.githubusercontent.com/CrowdStrike/Cloud-Azure/master/vm-extensions/scripts/install.sh
    chmod 755 stage1
    #TODO: Add arm / ubuntu version detection
    ./stage1
    rm stage1
fi
