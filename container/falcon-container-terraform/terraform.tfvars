## PLEASE change the following variables

## Do not store secrets here Use environment variables instead
## Example:   export TF_VAR_falcon_client_id="ASDF123"

# falcon_client_id = ""
# falcon_client_secret = ""
# falcon_cid = ""
# falcon_cloud = ""

## IP Address used for NSG to admin vm
#
# your_ip_address = ""

## Some sane defaults, no need to edit these
## That is unless there is a need :-)
cloud_region = "westus"
resource_group_name = "rg_"
tags = {
    owner = "demo.group"
    environment = "demo"
}
# suffix = "01"
prefix = "demo"
vmname = "aksadminvm"
internal_network_as = ["10.0.0.0/16"]
internal_network_sn = ["10.0.2.0/24"]
