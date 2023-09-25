#!/bin/bash
#source ./govc.env

# source govc.env
if [[ ! -e govc.env ]]; then
    echo "govc.env file not found. please create one by cloning example and filling values as needed."
    exit 1
fi
source ./govc.env

#Get cluster name
echo "enter name for new cluster"
read TKGCLUSTERNAME

#Get KUBEVIPVIP IP
echo
echo "enter IP address for new cluster K8S API "
read VSPHERE_CONTROL_PLANE_ENDPOINT



#get datacenter
echo
DATACENTERSLIST=$(govc find / -type d  | cut -d "/" -f2 | sort)
if [ $? -eq 0 ]
then
    echo
    echo "Select desired datacenter or CTRL-C to quit"
    echo
    select DATACENTER in $DATACENTERSLIST; do 
        echo "Datacenter selected :  $DATACENTER"
        GOVC_DC=$DATACENTER
        break
    done
else
    echo "problem getting datacenters list via govc" >&2
    exit 1
fi

#get cluster
echo
CLUSTERSLIST=$(govc find -dc="${GOVC_DC}" -type ClusterComputeResource | rev | cut -d "/" -f1 | rev )
if [ $? -eq 0 ]
then
    echo
    echo "Select desired cluster or CTRL-C to quit"
    echo
    select CLUSTER in $CLUSTERSLIST; do 
        echo "Cluster selected :  $CLUSTER"
        GOVC_CLUSTER=$CLUSTER
        break
    done
else
    echo "problem getting clusters list via govc" >&2
    exit 1
fi

#get Datastores
echo
DATASTORES=$(govc ls -dc="${GOVC_DC}" datastore )
if [ $? -eq 0 ]
then
    #echo "${DATASTORES}"
    echo
    echo "Select datastore where tkg cluster will run or CTRL-C to quit"
    echo

    select DS in $DATASTORES; do 
        echo "ResourcePool selected : $DS"
        DATASTORE=$DS
        break
    done
else
    echo "problem getting datastores list via govc" >&2
    exit 1
fi

#get ResourcePool
echo
RESOURCEPOOLS=$(govc find -dc="${GOVC_DC}" -type ResourcePool . | rev | cut -d "/" -f1 | rev )
if [ $? -eq 0 ]
then
    #echo "${RESOURCEPOOLS}"
    echo
    echo "Select resourcepool where tkg cluster will run or CTRL-C to quit"
    echo

    select RP in $RESOURCEPOOLS; do 
        echo "ResourcePool selected : $RP"
        RESOURCEPOOL=$RP
        break
    done
else
    echo "problem getting hosts list via govc" >&2
    exit 1
fi

#get FOLDER
echo
IFS='
'
FOLDERS=$(govc ls -dc="${GOVC_DC}" -t Folder -json=true vm |jq -r .elements[].Path)
if [ $? -eq 0 ]
then
    #echo "${FOLDERS}"
    echo
    echo "Select folder where tkg cluster will run or CTRL-C to quit"
    echo

    select FD in ${FOLDERS}; do 
        echo "Folder selected : $FD"
        VMFOLDER=$FD
        break
    done
else
    echo "problem getting folders list via govc" >&2
    exit 1
fi
unset IFS

#get Portgroups
echo
NETWORKS=$(govc ls -dc="${GOVC_DC}" -t DistributedVirtualPortgroup network)
if [ $? -eq 0 ]
then
    #echo "${NETWORKS}"
    echo
    echo "Select portgroup where tkg cluster will run or CTRL-C to quit"
    echo

    select NET in $NETWORKS; do 
        echo "Folder selected : $NET"
        PGNETWORK=$NET
        break
    done
else
    echo "problem getting portgroups list via govc" >&2
    exit 1
fi

#setting same password as for GOVC
ENCPWD=$(echo "${GOVC_PASSWORD}"|base64)
VSPHERE_PASSWORD="<encoded:${ENCPWD}>"

#SSH PUB KEY
echo
PUBKEYS=$(ls  ~/.ssh/*.pub)
if [ $? -eq 0 ]
then
    #echo "${PUBKEYS}"
    echo
    echo "Select ssh key to use for tkg cluster or CTRL-C to quit"
    echo

    select PUB in $PUBKEYS; do 
        echo "Key selected : $PUB"
        VSPHERE_SSH_AUTHORIZED_KEY=$(cat $PUB)
        break
    done
else
    echo "problem getting portgroups list via govc" >&2
    exit 1
fi

#get VSPHERE_STORAGE_POLICY_ID
echo
IFS='
'
POLICIES=$(govc storage.policy.ls -json=true | jq -r .Profile[].Name)
if [ $? -eq 0 ]
then
    #echo "${POLICIES}"
    echo
    echo "Select storage policy for tkg cluster or CTRL-C to quit"
    echo

    select POLICY in $POLICIES; do 
        echo "Storage Policy selected : $POLICY"
        VSPHERE_STORAGE_POLICY_ID="$POLICY"
        break
    done
else
    echo "problem getting portgroups list via govc" >&2
    exit 1
fi
unset IFS

#get Templates
echo
TEMPLATES=$(govc find -type m / -config.template true)
if [ $? -eq 0 ]
then
    echo
    echo "Select template for tkg cluster or CTRL-C to quit"
    echo

    select TEMPL in $TEMPLATES; do 
        echo "Template selected : $TEMPL"
        VSPHERE_TEMPLATE=$TEMPL
        break
    done
else
    echo "problem getting templates list via govc" >&2
    exit 1
fi

#REGION=${GOVC_DC}-${GOVC_CLUSTER}
REGION=${GOVC_CLUSTER}

#Create Zones CRDs
[ ! -d ${CLUSTER} ] && mkdir ${CLUSTER}

VCSA=$(echo "${GOVC_URL}"| rev | cut -d "/" -f1 | rev)

echo
echo "Create cluster yaml"
CLUSTERYAML=$(cat ./tkgm-cluster-template.yaml)
CLUSTERYAML=$(echo "${CLUSTERYAML}" | yq e '.CLUSTER_NAME = "'${TKGCLUSTERNAME}'" ' -)
CLUSTERYAML=$(echo "${CLUSTERYAML}" | yq e '.VSPHERE_DATACENTER = "'${GOVC_DC}'" ' -)
CLUSTERYAML=$(echo "${CLUSTERYAML}" | yq e '.VSPHERE_SERVER = "'${VCSA}'" ' -)
CLUSTERYAML=$(echo "${CLUSTERYAML}" | yq e '.VSPHERE_DATASTORE = "'${DATASTORE}'" ' -)
CLUSTERYAML=$(echo "${CLUSTERYAML}" | yq e '.VSPHERE_FOLDER = "'"${VMFOLDER}"'" ' -)
CLUSTERYAML=$(echo "${CLUSTERYAML}" | yq e '.VSPHERE_NETWORK = "'${PGNETWORK}'" ' -)
CLUSTERYAML=$(echo "${CLUSTERYAML}" | yq e '.VSPHERE_RESOURCE_POOL = "'${RESOURCEPOOL}'" ' -)
CLUSTERYAML=$(echo "${CLUSTERYAML}" | yq e '.VSPHERE_SSH_AUTHORIZED_KEY = "'"${VSPHERE_SSH_AUTHORIZED_KEY}"'" ' -)
CLUSTERYAML=$(echo "${CLUSTERYAML}" | yq e '.VSPHERE_USERNAME = "'${GOVC_USERNAME}'" ' -)
CLUSTERYAML=$(echo "${CLUSTERYAML}" | yq e '.VSPHERE_PASSWORD = "'${VSPHERE_PASSWORD}'" ' -)
CLUSTERYAML=$(echo "${CLUSTERYAML}" | yq e '.VSPHERE_CONTROL_PLANE_ENDPOINT = "'${VSPHERE_CONTROL_PLANE_ENDPOINT}'" ' -)
CLUSTERYAML=$(echo "${CLUSTERYAML}" | yq e '.VSPHERE_STORAGE_POLICY_ID = "'"${VSPHERE_STORAGE_POLICY_ID}"'" ' -)
CLUSTERYAML=$(echo "${CLUSTERYAML}" | yq e '.VSPHERE_TEMPLATE = "'"${VSPHERE_TEMPLATE}"'" ' -)

echo "${CLUSTERYAML}" > ${TKGCLUSTERNAME}.yaml
