source ../govc_factory
CPOD_01_VM_PATH="/intel-DC/vm/cPod-CLUSTER-ANNEX-01-DC02"
CPOD_02_VM_PATH="/intel-DC/vm/cPod-CLUSTER-ANNEX-02-DC02"
CPOD_03_VM_PATH="/intel-DC/vm/cPod-CLUSTER-CENTRAL-DC02"

govc vm.power -off  "${CPOD_01_VM_PATH}-esx01"
govc vm.power -off  "${CPOD_02_VM_PATH}-esx01"
govc vm.power -off  "${CPOD_03_VM_PATH}-esx01"
