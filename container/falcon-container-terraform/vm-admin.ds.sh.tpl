#!/bin/bash

export HOME=/root

main(){
    export DEBIAN_FRONTEND=noninteractive
    install_deps
    fetch_falcon_secrets
    download_build_falcon_sensor
    push_falcon_sensor_to_image_registry
    deploy_falcon_helm
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

download_build_falcon_sensor(){
    tmpdir=$(mktemp -d)
    pushd "$tmpdir" > /dev/null
      git clone https://github.com/CrowdStrike/Dockerfiles.git
      cd Dockerfiles
      falcon_sensor_download --os-name=Ubuntu --os-version=14/16/18/20 --sensor-version=latest
      local_repo=falcon-node-sensor
      tag=ubuntu
      local_tag="$local_repo:$tag"
      docker build --no-cache --build-arg \
        BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ') \
        --build-arg VCS_REF=$(git rev-parse --short HEAD) \
        --build-arg FALCON_PKG=$(ls falcon-sensor_6*) \
        -t "$local_tag" \
        -f Dockerfile.ubuntu .
    popd > /dev/null
    rm -rf "$tmpdir"
}

push_falcon_sensor_to_image_registry(){
    sudo az acr login --name "${ACR_LOGIN_SERVER}"
    IMAGE_REGISTRY=$(echo "${ACR_LOGIN_SERVER}" | tr '[:upper:]' '[:lower:]')
    FALCON_IMAGE_URI="$IMAGE_REGISTRY/$local_repo"
    sudo docker tag "$local_tag" "$FALCON_IMAGE_URI:$tag"
    sudo docker push "$FALCON_IMAGE_URI:$tag"
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
    export CID=$FALCON
}

deploy_falcon_helm(){
    curl https://baltocdn.com/helm/signing.asc | sudo apt-key add -
    sudo apt-get install apt-transport-https --yes
    echo "deb https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
    sudo apt-get update
    sudo apt-get install helm
    helm repo add crowdstrike https://crowdstrike.github.io/falcon-helm
    helm upgrade --install falcon-helm crowdstrike/falcon-sensor \
        -n falcon-system --create-namespace \
        --set falcon.cid="$FALCON_CID" \
        --set node.image.repository="$FALCON_IMAGE_URI" \
        --set node.image.tag="$tag"
    sleep 5
    kubectl wait --for=condition=ready pod -n falcon-system -l app=falcon-helm-falcon-sensor
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
    echo "[ -f $LIVE_LOG ] && tail -n 1000 -f $LIVE_LOG"
)  >> /etc/bash.bashrc

set -e -o pipefail

main "$@" >> $LIVE_LOG 2>&1

detection_uri(){
    aid=$(
        sudo kubectl exec deploy/vulnerable.example.com -c falcon-container -- \
            falconctl -g --aid | awk -F '"' '{print $2}')
    if [ $FALCON_CLOUD == 'us-2' ]
    then
        echo "https://falcon.us-2.crowdstrike.com/activity/detections/?filter=device_id:%27$aid%27&groupBy=none"
    else
        echo "https://falcon.crowdstrike.com/activity/detections/?filter=device_id:%27$aid%27&groupBy=none"
    fi
}

(
    echo "--------------------------------------------------------------------------------------------"
    echo "Demo initialization completed"
    echo "--------------------------------------------------------------------------------------------"
    echo "vulnerable.example.com is available at http://$(get_vulnerable_app_ip)/"
    echo "detections will appear at $(detection_uri)"
    echo "--------------------------------------------------------------------------------------------"
    echo "Useful commands:"
    echo "  # to get all running pods on the cluster"
    echo "  sudo kubectl get pods --all-namespaces"
    echo "  # to get Falcon agent/host ID of vulnerable.example.com"
    echo "  sudo kubectl exec $(sudo kubectl get pods -n falcon-system | awk 'FNR > 1' | awk '{print $1}') \\"
    echo "        -c falcon-node-sensor -n falcon-system -- falconctl  -g --aid"
    echo "  # to view Falcon Helm deployed pods"
    echo "  sudo kubectl get pods -n falcon-system"
    echo "  # to uninstall the vulnerable.example.com"
    echo "  sudo kubectl delete -f /yaml/vulnerable.example.yaml"
    echo "  # List Helm applications "
    echo "  sudo helm list -A"
    echo "  # Uninstall falcon-helm application "
    echo "  sudo helm uninstall falcon-helm -n falcon-system " 
    echo "--------------------------------------------------------------------------------------------"
) >> $LIVE_LOG


mv -f $LIVE_LOG $MOTD

for pid in $(ps aux | grep -v grep | grep tail | awk '{print $2}'); do
    kill "$pid"
done
