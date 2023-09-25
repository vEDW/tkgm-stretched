#!/bin/bash
#source ./govc.env

# source govc.env
if [[ ! -e govc.env ]]; then
    echo "govc.env file not found. please create one by cloning example and filling values as needed."
    exit 1
fi
source ./govc.env

#get datacenter
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
HOSTSLIST=$(govc find /${GOVC_DC}/host/${CLUSTER} -type h | rev | cut -d "/" -f1 | rev | sort)
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
HOSTSLIST=$(govc find /${GOVC_DC}/host/${CLUSTER} -type h | rev | cut -d "/" -f1 | rev | sort)
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


#get ResourcePool
RESOURCEPOOLS=$(govc find -dc="${GOVC_DC}" -type ResourcePool . | rev | cut -d "/" -f1 | rev )
if [ $? -eq 0 ]
then
    echo "${RESOURCEPOOLS}"
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

#REGION=${GOVC_DC}-${GOVC_CLUSTER}
REGION=${GOVC_CLUSTER}
echo "create tags"
# create region tags
TESTREGION=$(govc tags.category.ls |grep k8s-region)
if [ "$TESTREGION" == "" ];then
    govc tags.category.create -t ClusterComputeResource k8s-region
fi

govc tags.create -c k8s-region ${REGION}

# create zone tag category
TESTZONE=$(govc tags.category.ls |grep k8s-zone)
if [ "$TESTZONE" == "" ];then
    govc tags.category.create -t HostSystem k8s-zone
fi
govc tags.create -c k8s-zone ${ZONE01}
govc tags.create -c k8s-zone ${ZONE02}

# attach tag region to cluster
echo "Attach k8s-region Tag ${REGION} on  /${GOVC_DC}/host/${CLUSTER}"
govc tags.attach -c k8s-region -dc="${GOVC_DC}" ${REGION} /${GOVC_DC}/host/${CLUSTER}

echo "attach tags to zone01 hosts"
# attach zome tag to hosts
#Zone01
HOSTSZONE01=$(govc find /${GOVC_DC}/host/${CLUSTER} -type h |grep $ZONE01)
for HOST in $HOSTSZONE01; do
    # Zone01
    echo "tagging $HOST with ${ZONE01} "
    govc tags.attach -c k8s-zone  -dc="${GOVC_DC}" ${ZONE01} ${HOST}
done

echo "attach tags to zone02 hosts"
#Zone02
HOSTSZONE02=$(govc find /${GOVC_DC}/host/${CLUSTER} -type h |grep $ZONE02)
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
govc cluster.group.create -dc="${GOVC_DC}" -cluster=${CLUSTER} -name=${HGZONE01} -host
HOSTSZONE01=$(govc find ${GOVC_DC}/host/${CLUSTER} -type h |grep $ZONE01 | rev | cut -d "/" -f1 | rev )
govc cluster.group.change -dc="${GOVC_DC}" -cluster=${CLUSTER} -name=${HGZONE01} $HOSTSZONE01 

echo "create host groups zone02"
govc cluster.group.create -dc="${GOVC_DC}" -cluster=${CLUSTER} -name=${HGZONE02} -host
HOSTSZONE02=$(govc find ${GOVC_DC}/host/${CLUSTER} -type h |grep $ZONE02 | rev | cut -d "/" -f1 | rev )
govc cluster.group.change -dc="${GOVC_DC}" -cluster=${CLUSTER} -name=${HGZONE02} $HOSTSZONE02 

echo "create vm groups"
govc cluster.group.create -dc="${GOVC_DC}" -cluster=${CLUSTER} -name=${VMGROUP01} -vm
govc cluster.group.create -dc="${GOVC_DC}" -cluster=${CLUSTER} -name=${VMGROUP02} -vm


# create vm group to host group affinity "should" rules
echo "create affinity rules"
govc cluster.rule.create -dc="${GOVC_DC}" -enable -cluster=${CLUSTER} -name ${VMGROUP01}-${HGZONE01} -vm-host -vm-group ${VMGROUP01} -host-affine-group ${HGZONE01}
govc cluster.rule.create -dc="${GOVC_DC}" -enable -cluster=${CLUSTER} -name ${VMGROUP02}-${HGZONE02} -vm-host -vm-group ${VMGROUP02} -host-affine-group ${HGZONE02}


# check tags and rules
echo
echo "Tags Categories"
govc tags.category.ls |grep k8s

echo
echo "Tags"
govc tags.ls |grep k8s

echo
echo "Host and vm groups"
govc cluster.group.ls -dc=$GOVC_DC

echo
echo "Affinity Rules"
govc cluster.rule.ls -dc=$GOVC_DC

#Create Zones CRDs

[ ! -d ${CLUSTER} ] && mkdir ${CLUSTER}

VCSA=$(echo "${GOVC_URL}"| rev | cut -d "/" -f1 | rev)

ZONECRD=$(cat ./vSphereDeploymentZones.yaml)
ZONECRD=$(echo "${ZONECRD}" | yq e '.metadata.name = "'${ZONE01}'" ' -)
#ZONECRD=$(echo "${ZONECRD}" | yq e '.metadata.labels.region = "'${REGION}'" ' -)
#ZONECRD=$(echo "${ZONECRD}" | yq e '.metadata.labels.az = "'${ZONE01}'" ' -)
ZONECRD=$(echo "${ZONECRD}" | yq e '.spec.server = "'${VCSA}'" ' -)
ZONECRD=$(echo "${ZONECRD}" | yq e '.spec.failureDomain = "'${ZONE01}'" ' -)
ZONECRD=$(echo "${ZONECRD}" | yq e '.spec.placementConstraint.resourcePool = "'${RESOURCEPOOL}'" ' -)
echo "${ZONECRD}" > ${CLUSTER}/${ZONE01}-vSphereDeploymentZones.yaml

ZONECRD=$(cat ./vSphereDeploymentZones.yaml)
ZONECRD=$(echo "${ZONECRD}" | yq e '.metadata.name = "'${ZONE02}'" ' -)
#ZONECRD=$(echo "${ZONECRD}" | yq e '.metadata.labels.region = "'${REGION}'" ' -)
#ZONECRD=$(echo "${ZONECRD}" | yq e '.metadata.labels.az = "'${ZONE02}'" ' -)
ZONECRD=$(echo "${ZONECRD}" | yq e '.spec.server = "'${VCSA}'" ' -)
ZONECRD=$(echo "${ZONECRD}" | yq e '.spec.failureDomain = "'${ZONE02}'" ' -)
ZONECRD=$(echo "${ZONECRD}" | yq e '.spec.placementConstraint.resourcePool = "'${RESOURCEPOOL}'" ' -)
echo "${ZONECRD}" > ${CLUSTER}/${ZONE02}-vSphereDeploymentZones.yaml

#Create FailureDomain

REGIONDATASTORE=$(govc find -dc="${GOVC_DC}" -type Datastore | rev | cut -d "/" -f1 | rev |grep vsan)

ZONECRD=$(cat ./vSphereFailureDomain.yaml)
ZONECRD=$(echo "${ZONECRD}" | yq e '.metadata.name = "'${ZONE01}'" ' -)
ZONECRD=$(echo "${ZONECRD}" | yq e '.spec.region.name = "'${REGION}'" ' -)
ZONECRD=$(echo "${ZONECRD}" | yq e '.spec.zone.name = "'${ZONE01}'" ' -)
ZONECRD=$(echo "${ZONECRD}" | yq e '.spec.topology.datacenter = "'${GOVC_DC}'" ' -)
ZONECRD=$(echo "${ZONECRD}" | yq e '.spec.topology.computeCluster = "'${GOVC_CLUSTER}'" ' -)
ZONECRD=$(echo "${ZONECRD}" | yq e '.spec.topology.hosts.vmGroupName = "'${VMGROUP01}'" ' -)
ZONECRD=$(echo "${ZONECRD}" | yq e '.spec.topology.hosts.hostGroupName = "'${HGZONE01}'" ' -)
ZONECRD=$(echo "${ZONECRD}" | yq e '.spec.topology.datastore = "'${REGIONDATASTORE}'" ' -)

echo "${ZONECRD}" > ${CLUSTER}/${ZONE01}-vSphereFailureDomain.yaml

ZONECRD=$(cat ./vSphereFailureDomain.yaml)
ZONECRD=$(echo "${ZONECRD}" | yq e '.metadata.name = "'${ZONE02}'" ' -)
ZONECRD=$(echo "${ZONECRD}" | yq e '.spec.region.name = "'${REGION}'" ' -)
ZONECRD=$(echo "${ZONECRD}" | yq e '.spec.zone.name = "'${ZONE02}'" ' -)
ZONECRD=$(echo "${ZONECRD}" | yq e '.spec.topology.datacenter = "'${GOVC_DC}'" ' -)
ZONECRD=$(echo "${ZONECRD}" | yq e '.spec.topology.computeCluster = "'${GOVC_CLUSTER}'" ' -)
ZONECRD=$(echo "${ZONECRD}" | yq e '.spec.topology.hosts.vmGroupName = "'${VMGROUP02}'" ' -)
ZONECRD=$(echo "${ZONECRD}" | yq e '.spec.topology.hosts.hostGroupName = "'${HGZONE02}'" ' -)
ZONECRD=$(echo "${ZONECRD}" | yq e '.spec.topology.datastore = "'${REGIONDATASTORE}'" ' -)

echo "${ZONECRD}" > ${CLUSTER}/${ZONE02}-vSphereFailureDomain.yaml





