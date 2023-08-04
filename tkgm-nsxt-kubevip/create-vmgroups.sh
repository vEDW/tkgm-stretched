#!/bin/bash
source ../govc_cpod-V8STRNSX-MGMT

DOMAIN_DC01=cpod-v8strnsx-dc01.az-muc.cloud-garage.net
DOMAIN_DC02=cpod-v8strnsx-dc02.az-muc.cloud-garage.net
DATACENTER=/cPod-V8STRNSX-Stretched
CLUSTER=$(govc ls ${DATACENTER}/host)
REGION="stretched-cluster"
ZONE01="dc01"
ZONE02="dc02"
HGZONE01="hg-${ZONE01}"
HGZONE02="hg-${ZONE02}"
VMGROUP01="vm-${ZONE01}"
VMGROUP02="vm-${ZONE02}"

# create region tags
govc tags.category.create -t ClusterComputeResource k8s-region
govc tags.create -c k8s-region ${REGION}

# create zone tag category
govc tags.category.create -t HostSystem k8s-zone
govc tags.create -c k8s-zone ${ZONE01}
govc tags.create -c k8s-zone ${ZONE02}

# attach tag region to cluster
govc tags.attach -c k8s-region ${REGION} ${CLUSTER}

# attach zome tag to hosts

# Zone01
govc tags.attach -c k8s-zone ${ZONE01} esx01.${DOMAIN_DC01}
govc tags.attach -c k8s-zone ${ZONE01} esx02.${DOMAIN_DC01}
govc tags.attach -c k8s-zone ${ZONE01} esx03.${DOMAIN_DC01}
govc tags.attach -c k8s-zone ${ZONE01} esx04.${DOMAIN_DC01}

# ZONE02
govc tags.attach -c k8s-zone ${ZONE02} esx06.${DOMAIN_DC02}
govc tags.attach -c k8s-zone ${ZONE02} esx05.${DOMAIN_DC02}
govc tags.attach -c k8s-zone ${ZONE02} esx07.${DOMAIN_DC02}
govc tags.attach -c k8s-zone ${ZONE02} esx08.${DOMAIN_DC02}

# create host groups
govc cluster.group.create -cluster=${CLUSTER} -name=${HGZONE01} -host

govc cluster.group.change -cluster=${CLUSTER} -name=${HGZONE01} esx01.${DOMAIN_DC01} esx02.${DOMAIN_DC01} esx03.${DOMAIN_DC01} esx04.${DOMAIN_DC01}

govc cluster.group.create -cluster=${CLUSTER} -name=${HGZONE02} -host
govc cluster.group.change -cluster=${CLUSTER} -name=${HGZONE02} esx05.${DOMAIN_DC02} esx06.${DOMAIN_DC02} esx07.${DOMAIN_DC02} esx08.${DOMAIN_DC02}

govc cluster.group.create -cluster=${CLUSTER} -name=${VMGROUP01} -vm
govc cluster.group.create -cluster=${CLUSTER} -name=${VMGROUP02} -vm


# create vm group to host group affinity "should" rules

govc cluster.rule.create -enable -cluster=${CLUSTER} -name ${VMGROUP01}-${HGZONE01} -vm-host -vm-group ${VMGROUP01} -host-affine-group ${HGZONE01}
govc cluster.rule.create -enable -cluster=${CLUSTER} -name ${VMGROUP02}-${HGZONE02} -vm-host -vm-group ${VMGROUP02} -host-affine-group ${HGZONE02}

echo
echo "Tags Categories"
govc tags.category.ls |grep k8s

echo
echo "Tags"
govc tags.ls |grep k8s

