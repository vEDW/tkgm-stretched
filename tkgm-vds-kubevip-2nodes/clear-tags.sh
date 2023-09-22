#!/bin/bash
#source ./govc.env

# source govc.env
if [[ ! -e govc.env ]]; then
    echo "govc.env file not found. please create one by cloning example and filling values as needed."
    exit 1
fi
source ./govc.env

#get datacenter
DATACENTERSLIST=$(govc find / -type d  | cut -d "/" -f2)
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

echo "removing rules"
#get rules
RULESLIST=$(govc cluster.rule.ls -dc=$GOVC_DC)
if [ $? -eq 0 ]
then
    for RULE in $RULESLIST; do
        govc cluster.rule.remove  -dc=$GOVC_DC  -name $RULE
    done
else
    echo "problem getting rules list via govc" >&2
    exit 1
fi

echo "removing groups"
#get groups
GROUPSLIST=$(govc cluster.group.ls -dc=$GOVC_DC)
if [ $? -eq 0 ]
then
    for GROUP in $GROUPSLIST; do
        govc cluster.group.remove  -dc=$GOVC_DC  -name $GROUP
    done
else
    echo "problem getting group list via govc" >&2
    exit 1
fi

echo "removing tags"
#get groups
TAGSLIST=$(govc tags.ls )
if [ $? -eq 0 ]
then
    for TAG in $TAGSLIST; do

        ATTACHEDLIST=$(govc tags.attached.ls -dc=$GOVC_DC $TAG )
        for ATTACHED in $ATTACHEDLIST; do
            govc tags.detach -dc=$GOVC_DC $TAG $ATTACHED
        done
        govc tags.rm $TAG
    done
else
    echo "problem getting tags list via govc" >&2
    exit 1
fi

echo "removing tag categories"
#get groups
CATEGORIESLIST=$(govc tags.category.ls |grep k8s)
if [ $? -eq 0 ]
then
    for CATEGORY in $CATEGORIESLIST; do
        govc tags.category.rm  $CATEGORY
    done
else
    echo "problem getting categories list via govc" >&2
    exit 1
fi

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
