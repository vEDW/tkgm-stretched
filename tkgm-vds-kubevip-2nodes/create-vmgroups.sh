#!/bin/bash
#source ./govc.env

# source govc.env
if [[ ! -e govc.env ]]; then
    echo "govc.env file not found. please create one by cloning example and filling values as needed."
    exit 1
fi
source ./govc.env

#DOMAIN_DC01=cpod-v8strnsx-dc01.az-muc.cloud-garage.net
#DOMAIN_DC02=cpod-v8strnsx-dc02.az-muc.cloud-garage.net
#DATACENTER=/cPod-V8STRNSX-Stretched
#CLUSTER=$(govc ls ${DATACENTER}/host)
#REGION="stretched-cluster"
#ZONE01="dc01"
#ZONE02="dc02"
#HGZONE01="hg-${ZONE01}"
#HGZONE02="hg-${ZONE02}"
#VMGROUP01="vm-${ZONE01}"
#VMGROUP02="vm-${ZONE02}"

#get datacenter
DATACENTERSLIST=$(govc find / -type d)
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

#get zone01 domain
HOSTSLIST=$(govc find ${GOVC_DC}/host/${CLUSTER} -type h | rev | cut -d "/" -f1 | rev )
if [ $? -eq 0 ]
then
    echo "${HOSTSLIST}"
    echo
    echo "Select desired domain for zone01 or CTRL-C to quit"
    echo
    DOMAINLIST=$( echo "${HOSTSLIST}" |  cut -d "." -f2)

    select DOMAIN in $DOMAINLIST; do 
        echo "Domain selected for Zone01 : $DOMAIN"
        ZONE01=$DOMAIN
        break
    done
else
    echo "problem getting hosts list via govc" >&2
    exit 1
fi

#get zone02 domain
HOSTSLIST=$(govc find ${GOVC_DC}/host/${CLUSTER} -type h | rev | cut -d "/" -f1 | rev )
if [ $? -eq 0 ]
then
    echo "${HOSTSLIST}"
    echo
    echo "Select desired domain for zone02 or CTRL-C to quit"
    echo
    DOMAINLIST=$( echo "${HOSTSLIST}" |  cut -d "." -f2)

    select DOMAIN in $DOMAINLIST; do 
        echo "Domain selected for Zone01 : $DOMAIN"
        ZONE02=$DOMAIN
        break
    done
else
    echo "problem getting hosts list via govc" >&2
    exit 1
fi

REGION=${GOVC_DC}-${GOVC_CLUSTER}

echo "create tags"

# create region tags
govc tags.category.create -t ClusterComputeResource k8s-region
govc tags.create -c k8s-region ${REGION}

# create zone tag category
govc tags.category.create -t HostSystem k8s-zone
govc tags.create -c k8s-zone ${ZONE01}
govc tags.create -c k8s-zone ${ZONE02}

# attach tag region to cluster
govc tags.attach -c k8s-region -dc="${GOVC_DC}" ${REGION} ${GOVC_DC}/host/${CLUSTER}

echo "attach tags to zone01 hosts"
# attach zome tag to hosts
#Zone01
HOSTSZONE01=$(govc find ${GOVC_DC}/host/${CLUSTER} -type h |grep $ZONE01)
for HOST in $HOSTSZONE01; do
    # Zone01
    echo "tagging $HOST with ${ZONE01} "
    govc tags.attach -c k8s-zone  -dc="${GOVC_DC}" ${ZONE01} ${HOST}
done

echo "attach tags to zone02 hosts"
#Zone02
HOSTSZONE02=$(govc find ${GOVC_DC}/host/${CLUSTER} -type h |grep $ZONE02)
for HOST in $HOSTSZONE02; do
    # Zone01
    echo "tagging $HOST with ${ZONE02} "
    govc tags.attach -c k8s-zone  -dc="${GOVC_DC}" ${ZONE02} ${HOST}
done

HGZONE01="hg-${ZONE01}"
HGZONE02="hg-${ZONE02}"
VMGROUP01="vm-${ZONE01}"
VMGROUP02="vm-${ZONE02}"


# create host groups
echo "create host groups zone01"
govc cluster.group.create  -dc="${GOVC_DC}" -cluster=${CLUSTER} -name=${HGZONE01} -host
HOSTSZONE01=$(govc find ${GOVC_DC}/host/${CLUSTER} -type h |grep $ZONE01 | rev | cut -d "/" -f1 | rev )
govc cluster.group.change -cluster=${CLUSTER} -name=${HGZONE01} $HOSTSZONE01 

echo "create host groups zone02"
govc cluster.group.create -cluster=${CLUSTER} -name=${HGZONE02} -host
HOSTSZONE02=$(govc find ${GOVC_DC}/host/${CLUSTER} -type h |grep $ZONE02 | rev | cut -d "/" -f1 | rev )
govc cluster.group.change -cluster=${CLUSTER} -name=${HGZONE02} $HOSTSZONE02 

echo "create vm groups"
govc cluster.group.create -cluster=${CLUSTER} -name=${VMGROUP01} -vm
govc cluster.group.create -cluster=${CLUSTER} -name=${VMGROUP02} -vm


# create vm group to host group affinity "should" rules
echo "create affinity rules"
govc cluster.rule.create -dc="${GOVC_DC}" -enable -cluster=${CLUSTER} -name ${VMGROUP01}-${HGZONE01} -vm-host -vm-group ${VMGROUP01} -host-affine-group ${HGZONE01}
govc cluster.rule.create -dc="${GOVC_DC}" -enable -cluster=${CLUSTER} -name ${VMGROUP02}-${HGZONE02} -vm-host -vm-group ${VMGROUP02} -host-affine-group ${HGZONE02}

echo
echo "Tags Categories"
govc tags.category.ls |grep k8s

echo
echo "Tags"
govc tags.ls |grep k8s

