#!/bin/bash
while true; do
clear
IPS=$(kubectl get svc -A |grep test | awk '{print $5}')
for idx in ${IPS}; do
RESPONSE=$(curl -s -w '####%{response_code}' http://${idx} --connect-timeout 1)
HTTPSTATUS=$(echo ${RESPONSE} |awk -F '####' '{print $2}')
echo "${idx} : ${HTTPSTATUS}"
done
sleep 1
done