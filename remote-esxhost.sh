#!/bin/bash
#DC01

ROOT_PASSWD_DC01="xxxx"
domaindc01="abc-dc01.fqdn"
ROOT_PASSWD_DC02="xxxx"
domaindc02="abc-dc02.fqdn"

for idx in {1..4}; do
echo
echo "esx0$idx"
sshpass -p ${ROOT_PASSWD_DC01} ssh -o StrictHostKeyChecking=no root@esx0$idx.$domaindc01 $1
done

for idx in {5..8}; do
echo
echo "esx0$idx"
sshpass -p ${ROOT_PASSWD_DC02} ssh -o StrictHostKeyChecking=no root@esx0$idx.$domaindc02 $1
done