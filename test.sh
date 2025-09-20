set -e

echo "assumes that vm can be scheduled, aws emulation omde"
echo "this test is tailored for a 3 node cluster bot cluster"
echo "this test was done with NHC and MDR"
echo basic checks, but generally we assume that nhc and mdr are already configured properly and all nodes are helathy

set -x
trap "set +x ; oc delete -f manifests/vm.yaml ; killall oc" EXIT

oc apply -f manifests/cnv.yaml
oc apply -f manifests/mdrtpl.yaml -f manifests/nhc.yaml

oc create -f manifests/vm.yaml

[[ $(oc get nodes -o name -l node-role.kubernetes.io/worker | wc -l) > 2 ]]
#oc wait mcp worker --for condition=Degraded=False --for condition=Updated=True

# Ensure VMs are running
oc wait --for condition=Ready=True -f manifests/vm.yaml

NODE=$(oc get events --sort-by='{.metadata.creationTimestamp}' | grep -E "assigned.*fenced.*to.*" | grep -o -E "to .+" | sed "s#to ##" | tail -n1)
[[ -z "$NODE" ]] && exit 1
oc get nodes | grep $NODE || exit 1

# Fake that OOB is healthy
bash oob-set-node-condition.sh $NODE true

#oc get --watch-only events | grep -i -E "launcher|node|machine|health|fence|taint|drain|evict|delete" &
#oc get --watch-only vms &

# Fake that OOB is NOT healthy
bash oob-set-node-condition.sh $NODE false
TIME_OF_FAILURE=$(date +%s)

oc wait --for condition=Ready=False -f manifests/vm.yaml
TIME_OF_NODE_OUT_OF_SERVICE=$(date +%s)

oc wait --for condition=Ready=True -f manifests/vm.yaml
TIME_OF_VM_RUNNING_AGAIN=$(date +%s)

killall oc
oc delete -f manifests/vm.yaml --wait=false
set +x

echo "Time from node failure to initiating node remediation: $(( TIME_OF_NODE_OUT_OF_SERVICE - TIME_OF_FAILURE ))s"
echo "Time from initiated node remediation to VM running: $(( TIME_OF_VM_RUNNING_AGAIN - TIME_OF_NODE_OUT_OF_SERVICE ))s"
echo "TOTAL: Time from node failure to VM running: $(( TIME_OF_VM_RUNNING_AGAIN - TIME_OF_FAILURE ))s"
