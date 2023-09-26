source ../govc_factory
CPOD_VM_PATH="/az-dc01/vm/cPod-xxx-DC02"

govc vm.power -on  "${CPOD_VM_PATH}-esx01"
govc vm.power -on  "${CPOD_VM_PATH}-esx02"
govc vm.power -on  "${CPOD_VM_PATH}-esx03"
govc vm.power -on  "${CPOD_VM_PATH}-esx04"