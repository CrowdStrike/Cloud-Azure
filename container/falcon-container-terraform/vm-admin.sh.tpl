#!/bin/bash

export HOME=/root

main(){
    export DEBIAN_FRONTEND=noninteractive
    install_deps
    fetch_falcon_secrets
    download_falcon_sensor
    push_falcon_sensor_to_image_registry
    deploy_falcon_container_sensor
    deploy_vulnerable_app
    wait_for_vulnerable_app
}

install_gofalcon() {
    gofalcon_version=0.2.2
    pkg=gofalcon-$gofalcon_version-1.x86_64.deb
    wget -q -O $pkg https://github.com/CrowdStrike/gofalcon/releases/download/v$gofalcon_version/$pkg
    apt install ./$pkg > /dev/null
}

install_deps(){
    sudo apt-get update
    sudo curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
    sudo apt install docker.io -y && sudo systemctl enable docker --now
    sudo az login --identity
    sudo az aks get-credentials --name "${AKS_CLUSTER_NAME}" --resource-group "${RG_NAME}" --admin
    sudo az aks install-cli
    install_gofalcon
    sudo mkdir -p /yaml
    wget -q -O /yaml/vulnerable.example.yaml https://raw.githubusercontent.com/isimluk/vulnapp/master/vulnerable.example.yaml
}

download_falcon_sensor(){
    tmpdir=$(mktemp -d)
    pushd "$tmpdir" > /dev/null
      falcon_sensor_download --os-name=Container
      local_tag=$(cat ./falcon-sensor-* | docker load -q | grep 'Loaded image: falcon-sensor:' | sed 's/^.*Loaded image: falcon-sensor://g')
    popd > /dev/null
    rm -rf "$tmpdir"
}

push_falcon_sensor_to_image_registry(){
    sudo az acr login --name "${ACR_LOGIN_SERVER}"
    IMAGE_REGISTRY=$(echo "${ACR_LOGIN_SERVER}" | tr '[:upper:]' '[:lower:]')
    FALCON_IMAGE_URI="$IMAGE_REGISTRY/falcon-sensor:latest"
    sudo docker tag "falcon-sensor:$local_tag" "$FALCON_IMAGE_URI"
    sudo docker push "$FALCON_IMAGE_URI"
}

fetch_falcon_secrets() {
    FALCON_CID=$(az keyvault secret show --name falcon-cid --vault-name ${VAULT_NAME} --query value | sed -e 's:"::g')
    FALCON_CLIENT_ID=$(az keyvault secret show --name falcon-client-id --vault-name ${VAULT_NAME} --query value | sed -e 's:"::g')
    FALCON_CLIENT_SECRET=$(az keyvault secret show --name falcon-client-secret --vault-name ${VAULT_NAME} --query value | sed -e 's:"::g')
    FALCON_CLOUD=$(az keyvault secret show --name falcon-cloud --vault-name ${VAULT_NAME} --query value | sed -e 's:"::g')
    export FALCON_CLIENT_SECRET
    export FALCON_CLIENT_ID
    export FALCON_CID
    export FALCON_CLOUD
}

deploy_falcon_container_sensor(){
    injector_file="/yaml/injector.yaml"
    sudo docker run --rm --entrypoint installer "$FALCON_IMAGE_URI" -cid "$FALCON_CID" -image "$FALCON_IMAGE_URI" > "$injector_file"

    sudo kubectl apply -f "$injector_file"

    sudo kubectl wait --for=condition=ready pod -n falcon-system -l app=injector
}

deploy_vulnerable_app(){
    sudo kubectl apply -f /yaml/vulnerable.example.yaml
}

wait_for_vulnerable_app(){
    echo "Waiting for load balancer to assign public IP to vulnerable.example.com"
    while [ -z "$(get_vulnerable_app_ip)" ]; do
        sleep 5
    done;
}

get_vulnerable_app_ip(){
    sudo kubectl get service vulnerable-example-com  -o yaml -o=jsonpath="{.status.loadBalancer.ingress[*].ip}"
}

progname=$(basename "$0")

die(){
    echo "$progname: fatal error: $*"
    exit 1
}

err_handler() {
    echo "Error on line $1"
}

trap 'err_handler $LINENO' ERR


MOTD=/etc/motd

LIVE_LOG=$MOTD.log

(
    echo "--------------------------------------------------------------------------------------------"
    echo "Welcome to the admin instance for your kubernetes demo cluster."
    echo "--------------------------------------------------------------------------------------------"
) > $LIVE_LOG


(
    echo 'sudo az login --identity 1> /dev/null'
    echo 'sudo az aks get-credentials --name "${AKS_CLUSTER_NAME}" --resource-group "${RG_NAME}" --admin 1> /dev/null'
    echo "[ -f $LIVE_LOG ] &&  tail -n 1000 -f $LIVE_LOG"
)  >> /etc/bash.bashrc

set -e -o pipefail

main "$@" >> $LIVE_LOG 2>&1

detection_uri(){
    aid=$(
        sudo kubectl exec deploy/vulnerable.example.com -c falcon-container -- \
            falconctl -g --aid | awk -F '"' '{print $2}')
    if [ $FALCON_CLOUD == 'us-2' ]
    then
        echo "https://falcon.us-2.crowdstrike.com/activity/detections?groupBy=none&sortBy=date%3Adesc"
    else
        echo "https://falcon.crowdstrike.com/activity/detections?groupBy=none&sortBy=date%3Adesc"
    fi
}

(
    echo "--------------------------------------------------------------------------------------------"
    echo "Demo initialization completed - Run 'bash' to initialize shell"
    echo "Run 'bash' to reinitialize shell if commands do not work"
    echo "--------------------------------------------------------------------------------------------"
    echo "vulnerable.example.com is available at http://$(get_vulnerable_app_ip)/"
    echo "detections will appear at $(detection_uri)"
    echo "--------------------------------------------------------------------------------------------"
    echo "Useful commands:"
    echo "  # to get all running pods on the cluster"
    echo "  sudo kubectl get pods --all-namespaces"
    echo "  # to get Falcon agent/host ID of vulnerable.example.com"
    echo "  sudo kubectl exec deploy/vulnerable.example.com -c crowdstrike-falcon-container -- falconctl -g --aid"
    echo "  # to view Falcon injector logs"
    echo "  sudo kubectl logs -n falcon-system deploy/injector"
    echo "  # to uninstall the vulnerable.example.com"
    echo "  sudo kubectl delete -f /yaml/vulnerable.example.yaml"
    echo "  # to uninstall the falcon container protection"
    echo "  sudo kubectl delete -f /yaml/injector.yaml"
    echo "--------------------------------------------------------------------------------------------"
) >> $LIVE_LOG

mv -f $LIVE_LOG $MOTD

for pid in $(ps aux | grep -v grep | grep tail | awk '{print $2}'); do
    kill "$pid"
done
